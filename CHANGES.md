# SmartHeaterC6 – Refactored Changes

All refactored source files are in the `refactored/` folder. Below is every change, why it was made, and which file(s) are affected.

---

## 1. SAFETY — Temperature Sensor Disconnect Detection
**Files:** `TempSensors.h`, `TempSensors.cpp`

**Problem:** When a DS18B20 sensor disconnected, the code silently kept the last valid reading forever. The fault-detection logic in the main loop never saw `NaN`, so the "sensor lost" fault never triggered — the heater could run uncontrolled on stale data.

**Fix:** After **3 consecutive failed reads**, the sensor value is set to `NAN`. A `_waterFailCount` / `_bodyFailCount` counter tracks consecutive failures. This ensures fault detection fires properly when a sensor physically disconnects.

---

## 2. SAFETY — DS18B20 85°C Power-On-Reset Rejection
**Files:** `Config.h`, `TempSensors.cpp`

**Problem:** The DS18B20 scratchpad defaults to 85.0°C on power-on. During early startup, a raw reading of exactly 85°C is almost certainly this POR artefact, not a real temperature — yet it would be accepted, potentially triggering a false over-temperature fault.

**Fix:** Added `isValidReading()` that rejects 85.0°C readings within `TEMP_POR_REJECT_WINDOW_MS` (30 seconds) after boot. Also rejects out-of-range readings (below -10°C or above 120°C).

---

## 3. SAFETY — millis() Overflow in Pause Timer
**Files:** `HeaterController.h`, `HeaterController.cpp`

**Problem:** `disableFor()` computed `_pauseUntil = millis() + minutes * 60000UL`. After ~49.7 days of uptime, `millis()` overflows to 0. If `_pauseUntil` was set shortly before overflow, the comparison `millis() >= _pauseUntil` would immediately appear true (pause instantly expires) or the pause would last far too long.

**Fix:** Replaced absolute-time `_pauseUntil` with **duration-based tracking**: `_pauseStartMs` + `_pauseDurationMs`. The check `(millis() - _pauseStartMs) >= _pauseDurationMs` uses unsigned subtraction which is immune to `millis()` overflow for durations under 49 days.

---

## 4. SAFETY — Relay Minimum Switching Interval
**Files:** `Config.h`, `HeaterRelay.h`, `HeaterRelay.cpp`

**Problem:** No protection against rapid on/off cycling. If the thermostat oscillated at the setpoint boundary, the relay could toggle every loop iteration (~ms intervals). This causes:
- Mechanical relay: contact welding, arc damage, reduced lifespan
- SSR: thermal stress from inrush currents

**Fix:** Added `RELAY_MIN_SWITCH_MS` (5 seconds). `on()` checks `canSwitch()` before activating — if the relay was recently turned off, the on request is silently deferred. `off()` always executes immediately (safety takes priority over dwell protection).

---

## 5. SAFETY — Max Target Safety Margin
**Files:** `Config.h`, `HeaterController.cpp`, `WebApi.cpp`

**Problem:** `setMaxTarget()` allowed values up to `HEATER_FAULT_TEMP` (85°C). A user could set maxTarget=85 and boost to 85°C. Due to thermal lag and hysteresis overshoot, water temperature could exceed the fault threshold, triggering an unnecessary hard fault.

**Fix:** Added `SAFETY_MARGIN_BELOW_FAULT` (3°C). Max target is now clamped to `HEATER_FAULT_TEMP - 3 = 82°C`. The WebApi validation mirrors this. `beginNVS()` also validates loaded values against this limit (in case the limit was tightened after a firmware update).

---

## 6. SAFETY — OTA No Longer Persists disabled=false
**Files:** `HeaterController.h`, `HeaterController.cpp`, `SmartHeaterC6.ino`

**Problem:** The OTA start callback called `heater.disable()` which writes `enabled=false` to NVS. If OTA completed but the system rebooted, the heater would come up as disabled — the user's previous "enabled" state was permanently lost.

**Fix:** Added `emergencyOff()` which turns the relay off **without writing to NVS**. OTA now uses `emergencyOff()`. After reboot, the heater restores its previous enabled state from NVS.

---

## 7. SAFETY — Centralized Fault Detection
**Files:** `FaultManager.h`, `FaultManager.cpp`, `SmartHeaterC6.ino`

**Problem:** Fault-detection state was scattered across 8+ global variables in the main `.ino` file (`tempNanSince`, `tempWasValid`, `bodyNanSince`, `relayWasOn`, etc.). This made the logic hard to audit, easy to break during changes, and created risk of state inconsistency.

**Fix:** Moved all fault-detection logic and state into `FaultManager` as static methods:
- `FaultManager::checkWaterTemp(float)`
- `FaultManager::checkBodyTemp(float)`
- `FaultManager::checkPower(bool relayOn, float powerW, bool powerValid)`
- `FaultManager::resetTimers()`

The main loop is now 3 clean calls instead of ~60 lines of raw fault-detection code.

---

## 8. STABILITY — Hardware Watchdog Timer
**Files:** `Config.h`, `SmartHeaterC6.ino`

**Problem:** No watchdog timer. If the main loop hung (e.g., I2C lockup, WiFi driver stall, library deadlock), the heater relay would remain in its last state indefinitely — potentially ON, causing uncontrolled heating.

**Fix:** Configured ESP-IDF Task Watchdog Timer (`esp_task_wdt`) with a 30-second timeout and `trigger_panic = true`. The loop feeds it every iteration via `esp_task_wdt_reset()`. A hang causes an automatic reboot. The fault loop also feeds it to prevent spurious resets during fault display.

---

## 9. OPTIMIZATION — NVS Write Throttling
**Files:** `Config.h`, `HeaterController.h`, `HeaterController.cpp`

**Problem:** Every call to `setTarget()`, `setHysteresis()`, `enable()`, `disable()`, `setCycleOnMinutes()`, etc. immediately wrote all settings to NVS flash. NVS uses the ESP32's SPI flash which has a ~100,000 write-cycle endurance. Frequent writes (especially during rapid API calls or setting adjustments) accelerate flash wear.

**Fix:** Settings changes now call `markNVSDirty()` instead of `saveToNVS()`. A `flushNVS()` method (called from the main loop) only writes to flash if the dirty flag is set **and** at least `NVS_WRITE_THROTTLE_MS` (30 seconds) has elapsed since the last write. Changes are held in RAM until the next flush.

---

## 10. OPTIMIZATION — WebSerial Bulk Response Building
**Files:** `WebSerial.cpp`

**Problem:** `handleConsoleLog()` built the HTTP response by appending one character at a time to a `String`. Each `out += (char)` call may trigger a `realloc()` — O(n²) time complexity and severe heap fragmentation on ESP32.

**Fix:** Uses `String::concat(const char*, size_t)` with bulk `memcpy` from the ring buffer. Handles wrap-around with two contiguous copies instead of per-byte iteration. Combined with `reserve()`, this is O(n) with a single allocation.

---

## 11. OPTIMIZATION — PowerMeter Failure Tracking
**Files:** `PowerMeter.h`, `PowerMeter.cpp`

**Problem:** PZEM read failures were silently ignored. No external visibility into communication health.

**Fix:** Added `_failCount` (consecutive failure counter) and `getConsecutiveFailures()` accessor. Allows monitoring code to detect persistent PZEM communication issues.

---

## 12. STABILITY — Target Clamping in Thermostat Logic
**Files:** `HeaterController.cpp`

**Problem:** Schedule slots could specify targets exceeding `_maxTarget`. The thermostat would heat to whatever the schedule said, bypassing the user-configured safety limit.

**Fix:** Added `if (target > _maxTarget) target = _maxTarget;` in `update()` after determining the effective target from boost/schedule/default priority chain.

---

## 13. STABILITY — NVS Load Validation
**Files:** `HeaterController.cpp`

**Problem:** If safety constants were tightened in a firmware update (e.g., lowering HEATER_FAULT_TEMP), NVS could contain old values that now exceed the new limits. The heater would operate with unsafe persisted settings.

**Fix:** `beginNVS()` now validates all loaded values: maxTarget is clamped to `HEATER_FAULT_TEMP - SAFETY_MARGIN_BELOW_FAULT`, target is clamped to maxTarget, and hysteresis is bounded to [0.5, 15.0].

---

## Summary of files changed vs. original

| File | Change |
|---|---|
| `Config.h` | New safety/timing constants |
| `HeaterRelay.h/cpp` | Min switching interval |
| `TempSensors.h/cpp` | Disconnect detection, POR rejection, validation |
| `FaultManager.h/cpp` | Centralized fault-detection methods + state |
| `HeaterController.h/cpp` | millis() fix, NVS throttle, emergency off, target clamping |
| `PowerMeter.h/cpp` | Failure counter |
| `WebSerial.cpp` | Bulk response building |
| `WebApi.cpp` | Safety margin in maxTarget validation |
| `SmartHeaterC6.ino` | Watchdog, clean fault detection, emergencyOff for OTA |
| `StatusLed.*`, `Display.*`, `Button.*`, `Scheduler.*`, `TimeSync.*`, `Stats.*` | Unchanged (copied as-is) |
