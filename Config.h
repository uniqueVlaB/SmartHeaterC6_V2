#pragma once

// ── Board ────────────────────────────────────────────────
// MakerGO ESP32-C6 SuperMini
//
// Arduino IDE board: "MakerGO ESP32-C6 SuperMini"

// ── Pin assignments ──────────────────────────────────────
#define PIN_LED_WS2812      8  // Onboard RGB LED
#define PIN_RELAY           20  // SSR/Relay control
#define PIN_TEMP_SENSOR     19  // DS18B20 OneWire DQ
#define PIN_SDA             15  // I2C SDA  (OLED)
#define PIN_SCL             14  // I2C SCL  (OLED)
#define PIN_BUTTON          2   // Push button (active LOW, internal pull-up)
#define PIN_PZEM_TX         0   // ESP32 TX → PZEM RX  (UART1)
#define PIN_PZEM_RX         1   // ESP32 RX ← PZEM TX  (UART1, level-shift 5V→3.3V!)

// ── Aliases ──────────────────────────────────────────────
#define PIN_SSR_RELAY       PIN_RELAY
#define PIN_ONEWIRE         PIN_TEMP_SENSOR
#define PIN_I2C_SDA         PIN_SDA
#define PIN_I2C_SCL         PIN_SCL

// ── WiFi ─────────────────────────────────────────────────
#define WIFI_SSID         "REMOVED_WIFI_SSID"
#define WIFI_PASSWORD     "REMOVED_WIFI_PASSWORD"
#define WIFI_RECONNECT_INTERVAL_MS  10000UL  // min ms between reconnect attempts

// ── OTA ──────────────────────────────────────────────────
#define OTA_HOSTNAME        "SmartHeater"
#define OTA_PASSWORD        WIFI_PASSWORD

// ── NTP / Time ───────────────────────────────────────────
#define NTP_SERVER1         "pool.ntp.org"
#define NTP_SERVER2         "time.google.com"
#define NTP_TIMEZONE        "EET-2EEST,M3.5.0/3,M10.5.0/4"  // Ukraine (Kyiv)
#define NTP_SYNC_INTERVAL_MS (15UL * 60UL * 1000UL)          // 15 minutes

// ── OLED display ─────────────────────────────────────────
#define DISPLAY_I2C_ADDR    0x3C
#define OLED_I2C_ADDR       DISPLAY_I2C_ADDR
#define DISPLAY_WIDTH       128
#define DISPLAY_HEIGHT      128
#define DISPLAY_TIMEOUT_MS  30000UL
#define DISPLAY_UPDATE_MS   1000UL
#define DISPLAY_REFRESH_MS  DISPLAY_UPDATE_MS

// ── Heater / thermostat ──────────────────────────────────
#define HEATER_DEFAULT_TARGET   55.0f   // °C  default target on fresh install
#define HEATER_MAX_USER_TARGET  75.0f   // °C  default upper limit user can set/boost to
#define HEATER_MAX_TEMP         88.0f   // °C  absolute hardware safety cut-off
#define HEATER_FAULT_TEMP       85.0f   // °C  over-temperature fault threshold (water)
#define BODY_FAULT_TEMP         80.0f   // °C  body sensor safety cut-off
#define HEATER_HYSTERESIS        5.0f   // °C  relay hysteresis band

// Safety margin: maxTarget must be at least this many degrees below HEATER_FAULT_TEMP
// Prevents user from setting a target so close to the fault threshold that overshoot trips it.
#define SAFETY_MARGIN_BELOW_FAULT  3.0f // °C

// ── Relay protection ─────────────────────────────────────
// Minimum time relay must remain in one state before switching.
// Prevents rapid on/off cycling that damages mechanical relays and contactors.
#define RELAY_MIN_SWITCH_MS     5000UL  // ms

// ── Fault / safety ───────────────────────────────────────
#define TEMP_SENSOR_LOST_MS         30000UL // ms  NaN temp duration before fault (water)
#define BODY_SENSOR_LOST_MS         60000UL // ms  NaN temp duration before fault (body)
#define RELAY_STUCK_POWER_W         10.0f   // W   power threshold for stuck-relay fault
#define RELAY_STUCK_DELAY_MS         6000UL // ms  grace period after relay turns OFF
#define HEATER_ELEMENT_CHECK_MS     15000UL // ms  grace after relay ON before checking power
#define HEATER_MIN_POWER_W          1000.0f // W   min expected draw when element is ON
#define HEATER_MAX_POWER_W          3000.0f // W   max rated power (overcurrent threshold)

// ── DS18B20 power-on-reset rejection ─────────────────────
// The DS18B20 scratchpad defaults to 85.0°C on power-on. Readings of exactly 85.0°C
// immediately after startup are almost certainly this POR artefact, not a real temperature.
#define TEMP_POR_VALUE              85.0f   // °C  DS18B20 power-on reset value
#define TEMP_POR_REJECT_WINDOW_MS   30000UL // ms  reject 85°C readings within this window after boot

// ── Temperature reading validation ───────────────────────
#define TEMP_MIN_VALID             -10.0f   // °C  reject readings below this
#define TEMP_MAX_VALID              120.0f  // °C  reject readings above this

// ── NVS write throttle ───────────────────────────────────
// Minimum interval between NVS writes to reduce flash wear.
// Changes are cached in RAM and flushed at this rate.
#define NVS_WRITE_THROTTLE_MS      30000UL  // ms

// ── Scheduler ────────────────────────────────────────────
#define SCHEDULER_MAX_SLOTS     8

// ── Timing ───────────────────────────────────────────────
#define PZEM_READ_INTERVAL_MS   2000UL  // ms  how often to poll PZEM
#define TEMP_READ_INTERVAL_MS   5000UL  // ms  how often to read DS18B20

// ── Button ───────────────────────────────────────────────
#define BUTTON_LONG_PRESS_MS    5000UL  // ms  hold to factory-reset all NVS settings

// ── Watchdog ─────────────────────────────────────────────
#define WDT_TIMEOUT_SEC         30      // seconds – hardware watchdog timeout
