#include <Arduino.h>
#include <WiFi.h>
#include <ArduinoOTA.h>
#include <esp_task_wdt.h>
#include "Config.h"
#include "StatusLed.h"
#include "HeaterRelay.h"
#include "TempSensors.h"
#include "Display.h"
#include "PowerMeter.h"
#include "Button.h"
#include "HeaterController.h"
#include "WebApi.h"
#include "WebSerial.h"
#include "TimeSync.h"
#include "Scheduler.h"
#include "FaultManager.h"
#include "Stats.h"

// ── Peripherals ─────────────────────────────────────────
StatusLed       led;
HeaterRelay     relay(PIN_SSR_RELAY);
TempSensors     tempSensors(PIN_ONEWIRE);
Display         display(PIN_I2C_SDA, PIN_I2C_SCL, DISPLAY_I2C_ADDR);
PowerMeter      pzem(PIN_PZEM_RX, PIN_PZEM_TX);
Button          button(PIN_BUTTON);

// ── Time & Schedule ─────────────────────────────────────
TimeSync timeSync;
Scheduler scheduler;
// ── Statistics ────────────────────────────────────────────
Stats stats;
// ── Logic ───────────────────────────────────────────────
HeaterController heater(relay, tempSensors);
WebApi           api(heater, tempSensors, pzem, relay, scheduler, timeSync, stats, led);

// ── Timing ──────────────────────────────────────────────
uint32_t lastTempRead    = 0;
uint32_t lastPzemRead    = 0;
uint32_t lastDisplayDraw = 0;
uint32_t lastStatsUpdate = 0;
uint32_t lastWiFiCheck   = 0;

// ─────────────────────────────────────────────────────────
// Shuts down relay, shows fault screen, keeps WDT/OTA/API alive.
[[noreturn]] void enterFaultLoop() {
    relay.begin();        // ensure relay pin is output
    relay.off();

    led.set(LedStatus::Fault);
    display.showFault(FaultManager::getCode(), FaultManager::getDetails());

    webSerial.printf("[FAULT LOOP] %s – %s\n",
                     FaultManager::getCodeStr(),
                     FaultManager::getDetails().c_str());

    while (true) {
        esp_task_wdt_reset();
        led.tick();
        ArduinoOTA.handle();
        api.handle();
        delay(10);
    }
}

// ─────────────────────────────────────────────────────────
void connectWiFi() {
    webSerial.printf("[WiFi] Connecting to %s", WIFI_SSID);
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    uint32_t start = millis();
    while (WiFi.status() != WL_CONNECTED) {
        led.tick();
        delay(250);
        webSerial.print(".");
        if (millis() - start > 15000) {
            webSerial.println("\n[WiFi] Connection failed – restarting");
            ESP.restart();
        }
    }
    webSerial.printf("\n[WiFi] Connected – IP: %s\n", WiFi.localIP().toString().c_str());
}

[[noreturn]] void enterFaultLoop();
// ─────────────────────────────────────────────────────────
void setup() {
    Serial.begin(115200);
    delay(500);
    webSerial.println("\n=== SmartHeater V2 ===");

    // ── Watchdog timer ──────────────────────────────────
    {
        const esp_task_wdt_config_t wdtCfg = {
            .timeout_ms = WDT_TIMEOUT_SEC * 1000,
            .idle_core_mask = 0,
            .trigger_panic = true
        };
        esp_task_wdt_init(&wdtCfg);
    }
    esp_task_wdt_add(NULL);

    // Init peripherals
    led.begin();
    led.set(LedStatus::Connecting);

    relay.begin();
    button.begin();
    tempSensors.begin();
    pzem.begin();

    if (!display.begin()) {
        webSerial.println("[Display] Running without display – check I2C wiring/address");
    } else {
        display.showSplash();
    }

    // Connect WiFi
    connectWiFi();
    if (FaultManager::isFaulted()) enterFaultLoop();

    // Start NTP time sync
    timeSync.begin();

    // Load persisted heater settings from NVS
    heater.beginNVS();

    // Load schedule from NVS and attach to heater
    scheduler.begin();
    heater.setScheduler(&scheduler, &timeSync);

    // Load statistics from NVS
    stats.beginNVS();

    // Start web server + serial console
    api.begin();
    webSerial.begin(api.server());

    // OTA firmware update
    ArduinoOTA.setHostname(OTA_HOSTNAME);
    ArduinoOTA.setPassword(OTA_PASSWORD);
   ArduinoOTA.onStart([]() {
    relay.off();
    heater.emergencyOff();
    webSerial.println("[OTA] Starting update – relay OFF");
});
ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    esp_task_wdt_reset();
});
ArduinoOTA.onEnd([]()   { webSerial.println("[OTA] Done – rebooting"); });
    ArduinoOTA.onError([](ota_error_t e) {
        webSerial.printf("[OTA] Error %u\n", e);
    });
    ArduinoOTA.begin();
    webSerial.printf("[OTA] Ready – hostname: %s\n", OTA_HOSTNAME);

    // Reset fault-detection timers so grace periods start from now,
    // not from millis()=0 (setup can take 30+ seconds with WiFi).
    FaultManager::resetTimers();
    lastStatsUpdate = millis();
    lastWiFiCheck   = millis();

    led.set(LedStatus::Idle);
    webSerial.println("[Setup] Ready");
}

// ─────────────────────────────────────────────────────────
void loop() {
    // ── Watchdog feed ────────────────────────────────────
    esp_task_wdt_reset();

    // ── Fault gate ───────────────────────────────────────
    if (FaultManager::isFaulted()) enterFaultLoop();

    uint32_t now = millis();

    // ── API restart check ───────────────────────────────
    if (api.shouldRestart()) {
        heater.flushNVS();
        delay(200);
        ESP.restart();
    }

    // ── WiFi reconnection watchdog ──────────────────────
    if (now - lastWiFiCheck >= WIFI_RECONNECT_INTERVAL_MS) {
        lastWiFiCheck = now;
        if (WiFi.status() != WL_CONNECTED) {
            webSerial.println("[WiFi] Disconnected – reconnecting...");
            WiFi.disconnect();
            WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
        }
    }

    // ── Read temperatures ───────────────────────────────
    if (now - lastTempRead >= TEMP_READ_INTERVAL_MS) {
        lastTempRead = now;
        tempSensors.requestReadings();
    }

    // ── Read power meter ────────────────────────────────
    if (now - lastPzemRead >= PZEM_READ_INTERVAL_MS) {
        lastPzemRead = now;
        pzem.requestReading();
    }

    // ── Fault detection (centralized) ────────────────────
    FaultManager::checkWaterTemp(tempSensors.getWaterTemp(), now);
    FaultManager::checkBodyTemp(tempSensors.getBodyTemp(), now);
    FaultManager::checkPower(pzem.getData(), relay.isOn(), now);
    if (FaultManager::isFaulted()) enterFaultLoop();

    // ── Thermostat logic ────────────────────────────────
    heater.update();

    // ── Periodic NVS flush ──────────────────────────────
    heater.flushNVS();

    // ── Statistics (update once per second) ──────────────
    if (now - lastStatsUpdate >= 1000) {
        lastStatsUpdate = now;
        const auto& pd = pzem.getData();
        stats.update(relay.isOn(), tempSensors.getWaterTemp(), pd.energy, pd.valid);
    }

    // ── Status LED ──────────────────────────────────────
    if (relay.isOn())
        led.set(LedStatus::Heating);
    else if (heater.isEnabled())
        led.set(LedStatus::Idle);
    else
        led.set(LedStatus::Off);
    led.tick();

    // ── Button → short press wakes display, long press factory-resets ──
    button.tick();
    if (button.wasPressed()) {
        display.wake();
    }
    if (button.wasLongPressed()) {
        webSerial.println("[RESET] Long press detected – factory reset!");
        relay.off();
        heater.resetNVS();
        scheduler.resetNVS();
        stats.resetNVS();
        display.wake();
        display.showFault(FaultCode::None, "Factory reset!\nRestarting...");
        delay(2000);
        ESP.restart();
    }
    display.checkTimeout(DISPLAY_TIMEOUT_MS);

    // ── Update display ──────────────────────────────────
    if (now - lastDisplayDraw >= DISPLAY_REFRESH_MS) {
        lastDisplayDraw = now;
        const auto& p = pzem.getData();
        const ScheduleSlot* slot = heater.getActiveSlot();
        String ts = timeSync.getTimeString();
        DisplayData dd {
            .waterTemp       = tempSensors.getWaterTemp(),
            .bodyTemp        = tempSensors.getBodyTemp(),
            .heaterOn        = relay.isOn(),
            .effectiveTarget = heater.getEffectiveTarget(),
            .maxTarget       = heater.getMaxTarget(),
            .boostTarget     = heater.getBoostTarget(),
            .powerW          = p.power,
            .voltage         = p.voltage,
            .current         = p.current,
            .energyKWh       = p.energy,
            .frequency       = p.frequency,
            .pf              = p.pf,
            .pauseRemaining  = heater.pauseRemaining(),
            .reason          = heater.getReason(),
            .schedFrom       = slot ? slot->fromMin : (uint16_t)0,
            .schedTo         = slot ? slot->toMin   : (uint16_t)0,
            .rssi            = (int8_t)WiFi.RSSI(),
            .timeSynced      = timeSync.isSynced(),
            .todayEnergyKWh  = stats.getTodayEnergyKWh(),
            .timeStr         = {},
            .ip              = {}
        };
        strncpy(dd.timeStr, ts.c_str(), sizeof(dd.timeStr) - 1);
        strncpy(dd.ip, WiFi.localIP().toString().c_str(), sizeof(dd.ip) - 1);
        display.showStatus(dd);
    }

    // ── NTP re-sync ─────────────────────────────────────
    timeSync.update();

    // ── OTA ─────────────────────────────────────────────
    ArduinoOTA.handle();

    // ── Handle HTTP requests ────────────────────────────
    api.handle();
}
