#include "WebApi.h"
#include "FaultManager.h"
#include "WebSerial.h"
#include "Tariff.h"
#include <Preferences.h>
#include <freertos/task.h>

#define SR_NVS_NS "sys_restart"

WebApi::WebApi(HeaterController& ctrl, TempSensors& temp,
               PowerMeter& pzem, HeaterRelay& relay,
               Scheduler& scheduler, TimeSync& timeSync,
               Stats& stats, StatusLed& led, Tariff& tariff, uint16_t port)
    : _server(port), _ctrl(ctrl), _temp(temp), _pzem(pzem), _relay(relay),
      _scheduler(scheduler), _timeSync(timeSync), _stats(stats), _led(led), _tariff(tariff) {}

void WebApi::begin() {
    // ── Heater control ──────────────────────────────────
    _server.on("/status",             HTTP_GET,  [this]() { handleStatus();         });
    _server.on("/heater/on",            HTTP_POST, [this]() { handleHeaterOn();       });
    _server.on("/heater/off",           HTTP_POST, [this]() { handleHeaterOff();      });
    _server.on("/heater/default/on",    HTTP_POST, [this]() { handleDefaultModeOn();  });
    _server.on("/heater/default/off",   HTTP_POST, [this]() { handleDefaultModeOff(); });
    _server.on("/heater/pause",        HTTP_POST, [this]() { handleHeaterPause();    });
    _server.on("/heater/boost",        HTTP_POST, [this]() { handleHeaterBoost();    });
    _server.on("/heater/target",      HTTP_POST, [this]() { handleSetTarget();      });
    _server.on("/heater/maxTarget",   HTTP_POST, [this]() { handleSetMaxTarget();   });
    _server.on("/heater/hysteresis",  HTTP_POST, [this]() { handleSetHysteresis(); });
    _server.on("/heater/hysteresis",  HTTP_GET,  [this]() { handleGetHysteresis(); });
    // ── Duty-cycle ────────────────────────────────────────────
    _server.on("/heater/cycle",        HTTP_GET,  [this]() { handleCycleGet();      });
    _server.on("/heater/cycle/on",     HTTP_POST, [this]() { handleCycleOn();        });
    _server.on("/heater/cycle/off",    HTTP_POST, [this]() { handleCycleOff();       });
    _server.on("/heater/cycle/config", HTTP_POST, [this]() { handleCycleConfig();    });
    _server.on("/power",              HTTP_GET,  [this]() { handlePower();          });
    _server.on("/power/reset",        HTTP_POST, [this]() { handleResetEnergy();    });
    // ── Schedule ────────────────────────────────────────
    _server.on("/schedule",           HTTP_GET,  [this]() { handleScheduleGet();    });
    _server.on("/schedule/add",       HTTP_POST, [this]() { handleScheduleAdd();    });
    _server.on("/schedule/edit",      HTTP_POST, [this]() { handleScheduleEdit();   });
    _server.on("/schedule/remove",    HTTP_POST, [this]() { handleScheduleRemove(); });
    _server.on("/schedule/enable",    HTTP_POST, [this]() { handleScheduleEnable(); });
    _server.on("/schedule/disable",   HTTP_POST, [this]() { handleScheduleDisable();});
    _server.on("/schedule/clear",     HTTP_POST, [this]() { handleScheduleClear();  });
    // ── LED ─────────────────────────────────────────────
    _server.on("/led",                HTTP_GET,  [this]() { handleLedGet();         });
    _server.on("/led/on",             HTTP_POST, [this]() { handleLedOn();          });
    _server.on("/led/off",            HTTP_POST, [this]() { handleLedOff();         });
    // ── Time ────────────────────────────────────────────
    _server.on("/time",               HTTP_GET,  [this]() { handleTime();           });
    // ── Fault ──────────────────────────────────────
    _server.on("/fault",              HTTP_GET,  [this]() { handleFault();          });
    // ── Stats ───────────────────────────────────────────
    _server.on("/stats",              HTTP_GET,  [this]() { handleStats();          });
    _server.on("/stats/price",        HTTP_POST, [this]() { handleSetPrice();        });
    _server.on("/stats/reset",        HTTP_POST, [this]() { handleStatsReset();     });    // ── Tariff ──────────────────────────────────────────────
    _server.on("/stats/tariff",        HTTP_GET,  [this]() { handleTariffGet();    });
    _server.on("/stats/tariff/on",     HTTP_POST, [this]() { handleTariffOn();     });
    _server.on("/stats/tariff/off",    HTTP_POST, [this]() { handleTariffOff();    });
    _server.on("/stats/tariff/config", HTTP_POST, [this]() { handleTariffConfig(); });    // ── System ──────────────────────────────────────────
    _server.on("/system/factory-reset", HTTP_POST, [this]() { handleFactoryReset(); });
    _server.on("/system/restart",       HTTP_POST, [this]() { handleRestart();      });
    _server.on("/system/periodic-restart",        HTTP_GET,  [this]() { handlePeriodicRestartGet();    });
    _server.on("/system/periodic-restart/on",     HTTP_POST, [this]() { handlePeriodicRestartOn();     });
    _server.on("/system/periodic-restart/off",    HTTP_POST, [this]() { handlePeriodicRestartOff();    });
    _server.on("/system/periodic-restart/config", HTTP_POST, [this]() { handlePeriodicRestartConfig(); });

    _server.onNotFound(                          [this]() { handleNotFound();       });


    loadPeriodicRestartNVS();

    _server.begin();
    webSerial.println("[WebApi] HTTP server started on port 80");
}

void WebApi::handle() {
    _server.handleClient();
    checkPeriodicRestart();
}

// ═══════════════════════════════════════════════════════
// CPU load helper
// ═══════════════════════════════════════════════════════

float WebApi::getCpuLoadPercent() {
    static uint32_t prevIdleTicks = 0;
    static uint32_t prevTotalMs   = 0;
    static float    lastLoad      = 0;

    TaskHandle_t idle = xTaskGetIdleTaskHandle();
    if (!idle) return lastLoad;

    uint32_t nowMs    = millis();
    uint32_t elapsed  = nowMs - prevTotalMs;
    if (elapsed < 1000) return lastLoad;   // update once per second

    TaskStatus_t info;
    vTaskGetInfo(idle, &info, pdFALSE, eRunning);

    uint32_t idleTicks = info.ulRunTimeCounter;
    uint32_t idleDelta = idleTicks - prevIdleTicks;

    // runtime counter is in us on ESP32
    float idlePercent = (float)idleDelta / (elapsed * 1000.0f) * 100.0f;
    lastLoad = 100.0f - idlePercent;
    if (lastLoad < 0) lastLoad = 0;
    if (lastLoad > 100) lastLoad = 100;

    prevIdleTicks = idleTicks;
    prevTotalMs   = nowMs;
    return lastLoad;
}

// ═══════════════════════════════════════════════════════
// Heater handlers
// ═══════════════════════════════════════════════════════

void WebApi::handleStatus() {
    const auto& p = _pzem.getData();
    float schedTarget = 0;
    bool  schedActive = false;
    const ScheduleSlot* activeSlot = nullptr;
    if (_timeSync.isSynced()) {
        struct tm t;
        if (_timeSync.getLocalTime(t))
            schedActive = _scheduler.isActive(t, schedTarget, activeSlot);
    }

    char buf[1100];
    float wt = _temp.getWaterTemp();
    float bt = _temp.getBodyTemp();
    char wtStr[12], btStr[12], stStr[128];
    if (isnan(wt)) strcpy(wtStr, "null"); else snprintf(wtStr, sizeof(wtStr), "%.1f", wt);
    if (isnan(bt)) strcpy(btStr, "null"); else snprintf(btStr, sizeof(btStr), "%.1f", bt);
    stStr[0] = '\0';
    if (schedActive && activeSlot) {
        char from[6], to[6];
        snprintf(from, sizeof(from), "%02d:%02d", activeSlot->fromMin / 60, activeSlot->fromMin % 60);
        snprintf(to,   sizeof(to),   "%02d:%02d", activeSlot->toMin   / 60, activeSlot->toMin   % 60);
        snprintf(stStr, sizeof(stStr),
            "\"scheduleTarget\":%.1f,"
            "\"scheduleFrom\":\"%s\","
            "\"scheduleTo\":\"%s\","
            "\"scheduleSlotId\":%d,",
            schedTarget, from, to, activeSlot->id);
    }

    snprintf(buf, sizeof(buf),
        "{\"fault\":%s,"
        "%s%s"
        "\"time\":\"%s\","
        "\"timeSynced\":%s,"
        "\"heater\":%s,"
        "\"enabled\":%s,"
        "\"defaultMode\":%s,"
        "\"reason\":\"%s\","
        "\"scheduleActive\":%s,"
        "\"target\":%.1f,"
        "\"effectiveTarget\":%.1f,"
        "\"maxTarget\":%.1f,"
        "\"hysteresis\":%.1f,"
        "\"pauseRemaining\":%lu,"
        "\"boostTarget\":%s,"
        "\"cycleMode\":%s,"
        "\"cycleOnMinutes\":%u,"
        "\"cycleOffMinutes\":%u,"
        "\"cyclePauseRemaining\":%lu,"
        "%s"
        "\"waterTemp\":%s,"
        "\"bodyTemp\":%s,"
        "\"voltage\":%.1f,"
        "\"current\":%.3f,"
        "\"power\":%.1f,"
        "\"energy\":%.3f,"
        "\"frequency\":%.1f,"
        "\"pf\":%.2f,"
        "\"cpuTemp\":%.1f,"
        "\"cpuLoad\":%.1f}",
        FaultManager::isFaulted() ? "true" : "false",
        FaultManager::isFaulted() ? "\"faultCode\":\"" : "",
        FaultManager::isFaulted() ? (String(FaultManager::getCodeStr()) + "\",\"faultDetails\":\"" + FaultManager::getDetails() + "\",").c_str() : "",
        _timeSync.getDateTimeString().c_str(),
        _timeSync.isSynced() ? "true" : "false",
        _relay.isOn() ? "true" : "false",
        _ctrl.isEnabled() ? "true" : "false",
        _ctrl.isDefaultModeEnabled() ? "true" : "false",
        heaterReasonStr(_ctrl.getReason()),
        schedActive ? "true" : "false",
        _ctrl.getTarget(),
        _ctrl.getEffectiveTarget(),
        _ctrl.getMaxTarget(),
        _ctrl.getHysteresis(),
        (unsigned long)_ctrl.pauseRemaining(),
        _ctrl.getBoostTarget() > 0 ? String(_ctrl.getBoostTarget(), 1).c_str() : "null",
        _ctrl.isCycleModeEnabled() ? "true" : "false",
        (unsigned)_ctrl.getCycleOnMinutes(),
        (unsigned)_ctrl.getCycleOffMinutes(),
        (unsigned long)_ctrl.getCyclePauseRemaining(),
        stStr,
        wtStr,
        btStr,
        p.voltage, p.current, p.power, p.energy, p.frequency, p.pf,
        temperatureRead(),
        getCpuLoadPercent());

    _server.sendHeader("Access-Control-Allow-Origin", "*");
    _server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    _server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
    _server.send(200, "application/json", buf);
}

void WebApi::handleHeaterOn() {
    _ctrl.enable();
    sendJson(200, "{\"status\":\"allowed\"}");
}

void WebApi::handleHeaterOff() {
    _ctrl.disable();
    sendJson(200, "{\"status\":\"disallowed\"}");
}

void WebApi::handleDefaultModeOn() {
    _ctrl.setDefaultMode(true);
    sendJson(200, "{\"status\":\"defaultMode\",\"enabled\":true}");
}

void WebApi::handleDefaultModeOff() {
    _ctrl.setDefaultMode(false);
    sendJson(200, "{\"status\":\"defaultMode\",\"enabled\":false}");
}

void WebApi::handleHeaterPause() {
    if (!_server.hasArg("minutes")) {
        sendJson(400, "{\"error\":\"missing 'minutes' parameter\"}");
        return;
    }
    uint32_t m = (uint32_t)_server.arg("minutes").toInt();
    if (m == 0 || m > 1440) {
        sendJson(400, "{\"error\":\"minutes must be 1-1440\"}");
        return;
    }
    _ctrl.disableFor(m);
    sendJson(200, "{\"status\":\"paused\",\"minutes\":" + String(m) + "}");
}

void WebApi::handleHeaterBoost() {
    if (!_server.hasArg("temp")) {
        sendJson(400, "{\"error\":\"missing 'temp' parameter\"}");
        return;
    }
    float t = _server.arg("temp").toFloat();
    float maxT = _ctrl.getMaxTarget();
    if (t <= 0 || t > maxT) {
        sendJson(400, "{\"error\":\"temp must be 1-" + String(maxT, 0) + "\"}");
        return;
    }
    _ctrl.boostTo(t);
    sendJson(200, "{\"status\":\"boosting\",\"boostTarget\":" + String(t, 1) + "}");
}

void WebApi::handleSetTarget() {
    if (!_server.hasArg("temp")) {
        sendJson(400, "{\"error\":\"missing 'temp' parameter\"}");
        return;
    }
    float t = _server.arg("temp").toFloat();
    float maxT = _ctrl.getMaxTarget();
    if (t <= 0 || t > maxT) {
        sendJson(400, "{\"error\":\"temp must be 1-" + String(maxT, 0) + "\"}");
        return;
    }
    _ctrl.setTarget(t);
    sendJson(200, "{\"target\":" + String(t, 1) + "}");
}

void WebApi::handleSetHysteresis() {
    if (!_server.hasArg("value")) {
        sendJson(400, "{\"error\":\"missing 'value' parameter\"}");
        return;
    }
    float v = _server.arg("value").toFloat();
    if (v < 0.5f || v > 15.0f) {
        sendJson(400, "{\"error\":\"value must be 0.5-15\"}");
        return;
    }
    _ctrl.setHysteresis(v);
    sendJson(200, "{\"hysteresis\":" + String(v, 1) + "}");
}

void WebApi::handleGetHysteresis() {
    sendJson(200, "{\"hysteresis\":" + String(_ctrl.getHysteresis(), 1) + "}");
}

void WebApi::handleSetMaxTarget() {
    if (!_server.hasArg("temp")) {
        sendJson(400, "{\"error\":\"missing 'temp' parameter\"}");
        return;
    }
    float t = _server.arg("temp").toFloat();
    if (t < 10.0f || t > HEATER_FAULT_TEMP) {
        sendJson(400, "{\"error\":\"temp must be 10-" + String(HEATER_FAULT_TEMP, 0) + "\"}");
        return;
    }
    _ctrl.setMaxTarget(t);
    sendJson(200, "{\"maxTarget\":" + String(t, 1) + "}");
}

void WebApi::handlePower() {
    const auto& p = _pzem.getData();
    char buf[192];
    snprintf(buf, sizeof(buf),
        "{\"valid\":%s,"
        "\"voltage\":%.1f,"
        "\"current\":%.3f,"
        "\"power\":%.1f,"
        "\"energy\":%.3f,"
        "\"frequency\":%.1f,"
        "\"pf\":%.2f}",
        p.valid ? "true" : "false",
        p.voltage, p.current, p.power, p.energy, p.frequency, p.pf);
    _server.send(200, "application/json", buf);
}

void WebApi::handleResetEnergy() {
    _pzem.resetEnergy();
    sendJson(200, "{\"status\":\"energy counter reset\"}");
}

// ═══════════════════════════════════════════════════════
// Schedule handlers
// ═══════════════════════════════════════════════════════

void WebApi::handleScheduleGet() {
    sendJson(200, _scheduler.toJson());
}

void WebApi::handleScheduleAdd() {
    if (!_server.hasArg("days") || !_server.hasArg("from") || !_server.hasArg("to")) {
        sendJson(400, "{\"error\":\"required: days, from, to\"}");
        return;
    }

    uint8_t  dayMask  = (uint8_t)_server.arg("days").toInt();
    uint16_t fromMin  = parseHHMM(_server.arg("from"));
    uint16_t toMin    = parseHHMM(_server.arg("to"));
    float    target   = _server.hasArg("target") ? _server.arg("target").toFloat() : 0.0f;

    if (fromMin == 0xFFFF || toMin == 0xFFFF) {
        sendJson(400, "{\"error\":\"invalid time format, use HH:MM\"}");
        return;
    }
    if (!_scheduler.addSlot(dayMask, fromMin, toMin, target)) {
        sendJson(400, "{\"error\":\"could not add slot (table full or invalid params)\"}");
        return;
    }
    sendJson(200, _scheduler.toJson());
}

// POST /schedule/edit?id=N  (optional: days, from, to, target; -1 = keep existing)
void WebApi::handleScheduleEdit() {
    if (!_server.hasArg("id")) {
        sendJson(400, "{\"error\":\"missing 'id'\"}");
        return;
    }
    uint8_t id = (uint8_t)_server.arg("id").toInt();

    int dayMask = _server.hasArg("days")   ? _server.arg("days").toInt()   : -1;
    int fromMin = _server.hasArg("from")   ? (int)parseHHMM(_server.arg("from")) : -1;
    int toMin   = _server.hasArg("to")     ? (int)parseHHMM(_server.arg("to"))   : -1;
    float target = _server.hasArg("target") ? _server.arg("target").toFloat() : -1.0f;

    if ((fromMin != -1 && fromMin == 0xFFFF) || (toMin != -1 && toMin == 0xFFFF)) {
        sendJson(400, "{\"error\":\"invalid time format, use HH:MM\"}");
        return;
    }

    if (!_scheduler.editSlot(id, dayMask, fromMin, toMin, target)) {
        sendJson(404, "{\"error\":\"slot not found\"}");
        return;
    }
    sendJson(200, _scheduler.toJson());
}

void WebApi::handleScheduleRemove() {
    if (!_server.hasArg("id")) {
        sendJson(400, "{\"error\":\"missing 'id'\"}");
        return;
    }
    uint8_t id = (uint8_t)_server.arg("id").toInt();
    if (!_scheduler.removeSlot(id)) {
        sendJson(404, "{\"error\":\"slot not found\"}");
        return;
    }
    sendJson(200, _scheduler.toJson());
}

void WebApi::handleScheduleEnable() {
    if (!_server.hasArg("id")) { sendJson(400, "{\"error\":\"missing 'id'\"}"); return; }
    uint8_t id = (uint8_t)_server.arg("id").toInt();
    if (!_scheduler.setEnabled(id, true)) { sendJson(404, "{\"error\":\"slot not found\"}"); return; }
    sendJson(200, _scheduler.toJson());
}

void WebApi::handleScheduleDisable() {
    if (!_server.hasArg("id")) { sendJson(400, "{\"error\":\"missing 'id'\"}"); return; }
    uint8_t id = (uint8_t)_server.arg("id").toInt();
    if (!_scheduler.setEnabled(id, false)) { sendJson(404, "{\"error\":\"slot not found\"}"); return; }
    sendJson(200, _scheduler.toJson());
}

void WebApi::handleScheduleClear() {
    _scheduler.clear();
    sendJson(200, "{\"status\":\"cleared\"}");
}

// ═══════════════════════════════════════════════════════
// LED handlers
// ═══════════════════════════════════════════════════════

void WebApi::handleLedGet() {
    sendJson(200, "{\"enabled\":" + String(_led.isEnabled() ? "true" : "false") + "}");
}

void WebApi::handleLedOn() {
    _led.setEnabled(true);
    sendJson(200, "{\"enabled\":true}");
}

void WebApi::handleLedOff() {
    _led.setEnabled(false);
    sendJson(200, "{\"enabled\":false}");
}

// ═══════════════════════════════════════════════════════
// System handlers
// ═══════════════════════════════════════════════════════

void WebApi::handleFactoryReset() {
    _relay.off();
    _ctrl.resetNVS();
    _scheduler.resetNVS();
    _stats.resetNVS();
    webSerial.println("[WebApi] Factory reset via API");
    sendJson(200, "{\"status\":\"factory reset – restarting\"}");
    _shouldRestart  = true;
    _restartStartMs = millis();
}

void WebApi::handleRestart() {
    webSerial.println("[WebApi] Restart requested via API");
    sendJson(200, "{\"status\":\"restarting\"}");
    _shouldRestart  = true;
    _restartStartMs = millis();
}

void WebApi::handlePeriodicRestartGet() {
    String json = "{\"enabled\":";
    json += _periodicRestartEnabled ? "true" : "false";
    json += ",\"intervalHours\":" + String(_periodicRestartIntervalH) + "}";
    sendJson(200, json);
}

void WebApi::handlePeriodicRestartOn() {
    _periodicRestartEnabled = true;
    savePeriodicRestartNVS();
    handlePeriodicRestartGet();
}

void WebApi::handlePeriodicRestartOff() {
    _periodicRestartEnabled = false;
    savePeriodicRestartNVS();
    handlePeriodicRestartGet();
}

void WebApi::handlePeriodicRestartConfig() {
    if (_server.hasArg("hours")) {
        uint16_t h = (uint16_t)_server.arg("hours").toInt();
        if (h < 1 || h > 168) {
            sendJson(400, "{\"error\":\"hours must be 1-168\"}");
            return;
        }
        _periodicRestartIntervalH = h;
    }
    if (_server.hasArg("enabled")) {
        _periodicRestartEnabled = (_server.arg("enabled") == "true" || _server.arg("enabled") == "1");
    }
    savePeriodicRestartNVS();
    handlePeriodicRestartGet();
}

void WebApi::loadPeriodicRestartNVS() {
    Preferences prefs;
    prefs.begin(SR_NVS_NS, true);
    _periodicRestartEnabled   = prefs.getBool("enabled", false);
    _periodicRestartIntervalH = prefs.getUShort("intervalH", 24);
    prefs.end();
    _lastPeriodicCheck = millis();
}

void WebApi::savePeriodicRestartNVS() {
    Preferences prefs;
    prefs.begin(SR_NVS_NS, false);
    prefs.putBool("enabled", _periodicRestartEnabled);
    prefs.putUShort("intervalH", _periodicRestartIntervalH);
    prefs.end();
}

void WebApi::checkPeriodicRestart() {
    if (!_periodicRestartEnabled) return;
    uint32_t intervalMs = (uint32_t)_periodicRestartIntervalH * 3600UL * 1000UL;
    if (millis() - _lastPeriodicCheck >= intervalMs) {
        webSerial.println("[WebApi] Periodic restart triggered");
        _shouldRestart  = true;
        _restartStartMs = millis();
    }
}

// ═══════════════════════════════════════════════════════
// Time handler
// ═══════════════════════════════════════════════════════

void WebApi::handleTime() {
    String json = "{";
    json += "\"synced\":"   + String(_timeSync.isSynced() ? "true" : "false") + ",";
    json += "\"datetime\":\"" + _timeSync.getDateTimeString() + "\",";
    json += "\"time\":\"" + _timeSync.getTimeString() + "\"";
    json += "}";
    sendJson(200, json);
}

// ═══════════════════════════════════════════════════════
// Fault handler
// ═══════════════════════════════════════════════════════

void WebApi::handleFault() {
    String json = "{";
    json += "\"faulted\":" + String(FaultManager::isFaulted() ? "true" : "false") + ",";
    json += "\"code\":\""    + String(FaultManager::getCodeStr()) + "\",";
    json += "\"details\":\"" + FaultManager::getDetails() + "\"";
    json += "}";
    sendJson(200, json);
}

// ═══════════════════════════════════════════════════════
// Duty-cycle handlers
// ═══════════════════════════════════════════════════════

static String cycleJson(const HeaterController& c) {
    String j = "{\"cycleMode\":";
    j += c.isCycleModeEnabled() ? "true" : "false";
    j += ",\"onMinutes\":"  + String(c.getCycleOnMinutes());
    j += ",\"offMinutes\":" + String(c.getCycleOffMinutes());
    j += ",\"pauseRemaining\":" + String(c.getCyclePauseRemaining());
    j += "}";
    return j;
}

void WebApi::handleCycleGet() {
    sendJson(200, cycleJson(_ctrl));
}

void WebApi::handleCycleOn() {
    _ctrl.setCycleMode(true);
    sendJson(200, cycleJson(_ctrl));
}

void WebApi::handleCycleOff() {
    _ctrl.setCycleMode(false);
    sendJson(200, cycleJson(_ctrl));
}

void WebApi::handleCycleConfig() {
    bool changed = false;
    if (_server.hasArg("on")) {
        uint16_t v = (uint16_t)_server.arg("on").toInt();
        if (v < 1 || v > 120) { sendJson(400, "{\"error\":\"'on' must be 1-120\"}"); return; }
        _ctrl.setCycleOnMinutes(v);
        changed = true;
    }
    if (_server.hasArg("off")) {
        uint16_t v = (uint16_t)_server.arg("off").toInt();
        if (v < 1 || v > 120) { sendJson(400, "{\"error\":\"'off' must be 1-120\"}"); return; }
        _ctrl.setCycleOffMinutes(v);
        changed = true;
    }
    if (!changed) { sendJson(400, "{\"error\":\"provide 'on' and/or 'off' params\"}"); return; }
    sendJson(200, cycleJson(_ctrl));
}

// ═══════════════════════════════════════════════════════
// Stats handlers
// ═══════════════════════════════════════════════════════

void WebApi::handleStats() {
    sendJson(200, _stats.toJson());
}

void WebApi::handleSetPrice() {
    if (!_server.hasArg("value")) {
        sendJson(400, "{\"error\":\"missing 'value' parameter\"}");
        return;
    }
    float price = _server.arg("value").toFloat();
    if (price < 0.0f || price > 100.0f) {
        sendJson(400, "{\"error\":\"value must be 0-100\"}");
        return;
    }
    _stats.setPricePerKWh(price);
    sendJson(200, "{\"pricePerKWh\":" + String(price, 4) + "}");
}

void WebApi::handleStatsReset() {
    _stats.resetNVS();
    sendJson(200, "{\"status\":\"stats reset\"}");
}

// ═══════════════════════════════════════════════════════
// Tariff handlers
// ═══════════════════════════════════════════════════════

void WebApi::handleTariffGet() {
    sendJson(200, _tariff.toJson());
}

void WebApi::handleTariffOn() {
    _tariff.setEnabled(true);
    sendJson(200, _tariff.toJson());
}

void WebApi::handleTariffOff() {
    _tariff.setEnabled(false);
    sendJson(200, _tariff.toJson());
}

void WebApi::handleTariffConfig() {
    bool changed = false;
    if (_server.hasArg("dayPrice")) {
        float v = _server.arg("dayPrice").toFloat();
        if (v < 0 || v > 100) { sendJson(400, "{\"error\":\"dayPrice out of range\"}"); return; }
        _tariff.setDayPrice(v);
        changed = true;
    }
    if (_server.hasArg("nightPrice")) {
        float v = _server.arg("nightPrice").toFloat();
        if (v < 0 || v > 100) { sendJson(400, "{\"error\":\"nightPrice out of range\"}"); return; }
        _tariff.setNightPrice(v);
        changed = true;
    }
    if (_server.hasArg("dayStart")) {
        int h = _server.arg("dayStart").toInt();
        if (h < 0 || h > 23) { sendJson(400, "{\"error\":\"dayStart must be 0-23\"}"); return; }
        _tariff.setDayStartHour((uint8_t)h);
        changed = true;
    }
    if (_server.hasArg("nightStart")) {
        int h = _server.arg("nightStart").toInt();
        if (h < 0 || h > 23) { sendJson(400, "{\"error\":\"nightStart must be 0-23\"}"); return; }
        _tariff.setNightStartHour((uint8_t)h);
        changed = true;
    }
    if (!changed) { sendJson(400, "{\"error\":\"no parameters provided\"}"); return; }
    sendJson(200, _tariff.toJson());
}

// ═══════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════

void WebApi::handleNotFound() {
    // Handle CORS preflight (OPTIONS) for every route
    if (_server.method() == HTTP_OPTIONS) {
        _server.sendHeader("Access-Control-Allow-Origin", "*");
        _server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        _server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
        _server.send(204);
        return;
    }
    sendJson(404, "{\"error\":\"not found\"}");
}

void WebApi::sendJson(int code, const String& json) {
    _server.sendHeader("Access-Control-Allow-Origin", "*");
    _server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    _server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
    _server.send(code, "application/json", json);
}

uint16_t WebApi::parseHHMM(const String& s) {
    int colon = s.indexOf(':');
    if (colon < 0) return 0xFFFF;
    int h = s.substring(0, colon).toInt();
    int m = s.substring(colon + 1).toInt();
    if (h < 0 || h > 23 || m < 0 || m > 59) return 0xFFFF;
    return (uint16_t)(h * 60 + m);
}
