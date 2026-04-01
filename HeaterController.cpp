#include "HeaterController.h"
#include <Preferences.h>
#include "WebSerial.h"

static const char* HC_NVS_NS         = "heater_ctrl";
static const char* HC_NVS_HYST       = "hysteresis";
static const char* HC_NVS_TARGET     = "target";
static const char* HC_NVS_MAX_TARGET = "maxTarget";
static const char* HC_NVS_ENABLE     = "enabled";
static const char* HC_NVS_DEF_MODE   = "defaultMode";
static const char* HC_NVS_CYCLE_EN   = "cycleEn";
static const char* HC_NVS_CYCLE_ON   = "cycleOnMin";
static const char* HC_NVS_CYCLE_OFF  = "cycleOffMin";

const char* heaterReasonStr(HeaterReason r) {
    switch (r) {
        case HeaterReason::Default:    return "DEFAULT";
        case HeaterReason::Schedule:   return "SCHEDULE";
        case HeaterReason::Boost:      return "BOOST";
        case HeaterReason::Paused:     return "PAUSED";
        case HeaterReason::CyclePause: return "CYCLE_PAUSE";
        case HeaterReason::Waiting:    return "WAITING";
        case HeaterReason::Disabled:   return "DISABLED";
        default:                       return "UNKNOWN";
    }
}

HeaterController::HeaterController(HeaterRelay& relay, TempSensors& sensors)
    : _relay(relay), _sensors(sensors) {}

void HeaterController::setScheduler(Scheduler* sched, TimeSync* ts) {
    _scheduler = sched;
    _timeSync  = ts;
}

void HeaterController::update() {
    float water = _sensors.getWaterTemp();
    float body  = _sensors.getBodyTemp();

    if (isnan(water) || water >= HEATER_MAX_TEMP) {
        _relay.off();
        return;
    }

    if (!isnan(body) && body >= BODY_FAULT_TEMP) {
        _relay.off();
        return;
    }

    if (!_enabled) {
        _relay.off();
        _reason = HeaterReason::Disabled;
        _activeSlot = nullptr;
        _scheduleActive = false;
        _cycleStarted = false;
        return;
    }

    // Timed pause
    if (_pauseUntil != 0) {
        if (millis() >= _pauseUntil) {
            _pauseUntil = 0;
            webSerial.println("[Heater] Pause expired - resuming");
        } else {
            _relay.off();
            _reason = HeaterReason::Paused;
            _cycleStarted = false;
            return;
        }
    }

    bool  active = false;
    float target = _target;
    HeaterReason reason = HeaterReason::Default;

    // 1. Boost
    if (_boostTarget > 0) {
        if (!isnan(water) && water >= _boostTarget) {
            webSerial.printf("[Heater] Boost reached %.1fC - done\n", _boostTarget);
            _boostTarget = 0;
            _relay.off();
            return;
        }
        active = true;
        target = _boostTarget;
        reason = HeaterReason::Boost;
    }

    // 2. Schedule
    _scheduleActive = false;
    _activeSlot = nullptr;
    if (_scheduler && _timeSync && _boostTarget <= 0) {
        if (_timeSync->isSynced()) {
            struct tm t;
            if (_timeSync->getLocalTime(t)) {
                float schedTarget = 0.0f;
                const ScheduleSlot* slot = nullptr;
                if (_scheduler->isActive(t, schedTarget, slot)) {
                    _scheduleActive = true;
                    _activeSlot = slot;
                    active = true;
                    if (schedTarget > 0.0f) target = schedTarget;
                    reason = HeaterReason::Schedule;
                }
            }
        }
    }

    // 3. Default mode
    if (!active) {
        if (_defaultModeEnabled) {
            active = true;
            reason = HeaterReason::Default;
        } else {
            _relay.off();
            _reason = HeaterReason::Waiting;
            _effectiveTarget = _target;
            _cycleStarted = false;
            return;
        }
    }

    // Duty-cycle gate
    if (_cycleEnabled) {
        uint32_t now = millis();
        if (!_cycleStarted) {
            _cycleStarted    = true;
            _cycleInPause    = false;
            _cyclePhaseStart = now;
        }
        uint32_t phaseDuration = _cycleInPause
            ? (uint32_t)_cycleOffMin * 60000UL
            : (uint32_t)_cycleOnMin  * 60000UL;
        if (now - _cyclePhaseStart >= phaseDuration) {
            _cycleInPause    = !_cycleInPause;
            _cyclePhaseStart = now;
            webSerial.printf("[Heater] Cycle: entering %s phase\n",
                          _cycleInPause ? "cool-down" : "heat");
        }
        if (_cycleInPause) {
            _relay.off();
            _reason = HeaterReason::CyclePause;
            return;
        }
    }

    _effectiveTarget = target;

    // Hysteresis thermostat
    if (water >= target) {
        _relay.off();
    } else if (water <= (target - _hysteresis)) {
        _relay.on();
    }
    _reason = reason;
}

void HeaterController::enable() {
    _enabled = true;
    _pauseUntil = 0;
    _boostTarget = 0;
    markDirty();
    webSerial.printf("[Heater] Allowed - target %.1fC\n", _target);
}

void HeaterController::disable() {
    _enabled = false;
    _pauseUntil = 0;
    _boostTarget = 0;
    _relay.off();
    markDirty();
    webSerial.println("[Heater] Disallowed");
}

void HeaterController::emergencyOff() {
    _relay.off();
    webSerial.println("[Heater] Emergency OFF (no NVS write)");
}

void HeaterController::disableFor(uint32_t minutes) {
    _pauseUntil = millis() + minutes * 60000UL;
    _boostTarget = 0;
    _relay.off();
    webSerial.printf("[Heater] Paused for %lu min\n", minutes);
}

void HeaterController::boostTo(float tempC) {
    if (tempC > 0 && tempC <= _maxTarget) {
        _boostTarget = tempC;
        _pauseUntil  = 0;
        webSerial.printf("[Heater] Boost to %.1fC\n", tempC);
    }
}

float HeaterController::getBoostTarget() const {
    return _boostTarget;
}

uint32_t HeaterController::pauseRemaining() const {
    if (_pauseUntil == 0) return 0;
    uint32_t now = millis();
    if (now >= _pauseUntil) return 0;
    return (_pauseUntil - now) / 1000;
}

bool HeaterController::isEnabled() const {
    return _enabled;
}

void HeaterController::setDefaultMode(bool enabled) {
    _defaultModeEnabled = enabled;
    markDirty();
    webSerial.printf("[Heater] Default mode %s\n", enabled ? "enabled" : "disabled");
}

bool HeaterController::isDefaultModeEnabled() const {
    return _defaultModeEnabled;
}

void HeaterController::setCycleMode(bool enabled) {
    _cycleEnabled     = enabled;
    _cycleStarted     = false;
    _cycleInPause     = false;
    _cyclePhaseStart  = 0;
    markDirty();
    webSerial.printf("[Heater] Cycle mode %s (on=%u min, off=%u min)\n",
                  enabled ? "enabled" : "disabled", _cycleOnMin, _cycleOffMin);
}

bool HeaterController::isCycleModeEnabled() const {
    return _cycleEnabled;
}

void HeaterController::setCycleOnMinutes(uint16_t min) {
    if (min >= 1 && min <= 120) {
        _cycleOnMin   = min;
        _cycleStarted = false;
        markDirty();
        webSerial.printf("[Heater] Cycle ON set to %u min\n", min);
    }
}

void HeaterController::setCycleOffMinutes(uint16_t min) {
    if (min >= 1 && min <= 120) {
        _cycleOffMin  = min;
        _cycleStarted = false;
        markDirty();
        webSerial.printf("[Heater] Cycle OFF set to %u min\n", min);
    }
}

uint16_t HeaterController::getCycleOnMinutes() const  { return _cycleOnMin;  }
uint16_t HeaterController::getCycleOffMinutes() const { return _cycleOffMin; }

uint32_t HeaterController::getCyclePauseRemaining() const {
    if (!_cycleEnabled || !_cycleInPause) return 0;
    uint32_t elapsed = millis() - _cyclePhaseStart;
    uint32_t total   = (uint32_t)_cycleOffMin * 60000UL;
    if (elapsed >= total) return 0;
    return (total - elapsed) / 1000;
}

void HeaterController::setMaxTarget(float tempC) {
    float cap = HEATER_FAULT_TEMP - SAFETY_MARGIN_BELOW_FAULT;
    if (tempC >= 10.0f && tempC <= cap) {
        _maxTarget = tempC;
        markDirty();
        webSerial.printf("[Heater] Max target set to %.1fC\n", _maxTarget);
    }
}

float HeaterController::getMaxTarget() const {
    return _maxTarget;
}

void HeaterController::setTarget(float tempC) {
    if (tempC > 0 && tempC <= _maxTarget) {
        _target = tempC;
        markDirty();
        webSerial.printf("[Heater] Target set to %.1fC\n", _target);
    }
}

float HeaterController::getTarget() const {
    return _target;
}

void HeaterController::setHysteresis(float deg) {
    if (deg >= 0.5f && deg <= 15.0f) {
        _hysteresis = deg;
        markDirty();
        webSerial.printf("[Heater] Hysteresis set to %.1fC\n", _hysteresis);
    }
}

float HeaterController::getHysteresis() const {
    return _hysteresis;
}

// ── NVS persistence ──────────────────────────────────────

void HeaterController::markDirty() {
    _nvsDirty = true;
}

void HeaterController::flushNVS() {
    if (!_nvsDirty) return;
    uint32_t now = millis();
    if (now - _lastNvsWrite < NVS_WRITE_THROTTLE_MS) return;
    saveToNVS();
    _nvsDirty = false;
    _lastNvsWrite = now;
}

void HeaterController::beginNVS() {
    Preferences prefs;
    prefs.begin(HC_NVS_NS, true);
    _target        = prefs.getFloat(HC_NVS_TARGET,     HEATER_DEFAULT_TARGET);
    _maxTarget     = prefs.getFloat(HC_NVS_MAX_TARGET,  HEATER_MAX_USER_TARGET);
    _hysteresis    = prefs.getFloat(HC_NVS_HYST,        HEATER_HYSTERESIS);
    _enabled       = prefs.getBool(HC_NVS_ENABLE,       false);
    _defaultModeEnabled = prefs.getBool(HC_NVS_DEF_MODE, true);
    _cycleEnabled  = prefs.getBool(HC_NVS_CYCLE_EN,     false);
    _cycleOnMin    = prefs.getUShort(HC_NVS_CYCLE_ON,   10);
    _cycleOffMin   = prefs.getUShort(HC_NVS_CYCLE_OFF,  5);
    prefs.end();
    _lastNvsWrite = millis();
    webSerial.printf("[Heater] NVS: target=%.1f max=%.1f hyst=%.1f en=%d def=%d cycle=%d(%u/%u)\n",
                  _target, _maxTarget, _hysteresis, _enabled, _defaultModeEnabled,
                  _cycleEnabled, _cycleOnMin, _cycleOffMin);
}

void HeaterController::resetNVS() {
    Preferences prefs;
    prefs.begin(HC_NVS_NS, false);
    prefs.clear();
    prefs.end();
    _target        = HEATER_DEFAULT_TARGET;
    _maxTarget     = HEATER_MAX_USER_TARGET;
    _hysteresis    = HEATER_HYSTERESIS;
    _enabled       = false;
    _defaultModeEnabled = true;
    _cycleEnabled  = false;
    _cycleOnMin    = 10;
    _cycleOffMin   = 5;
    _nvsDirty      = false;
    webSerial.println("[Heater] NVS reset");
}

void HeaterController::saveToNVS() const {
    Preferences prefs;
    prefs.begin(HC_NVS_NS, false);
    prefs.putFloat(HC_NVS_TARGET,      _target);
    prefs.putFloat(HC_NVS_MAX_TARGET,   _maxTarget);
    prefs.putFloat(HC_NVS_HYST,         _hysteresis);
    prefs.putBool(HC_NVS_ENABLE,        _enabled);
    prefs.putBool(HC_NVS_DEF_MODE,      _defaultModeEnabled);
    prefs.putBool(HC_NVS_CYCLE_EN,      _cycleEnabled);
    prefs.putUShort(HC_NVS_CYCLE_ON,    _cycleOnMin);
    prefs.putUShort(HC_NVS_CYCLE_OFF,   _cycleOffMin);
    prefs.end();
}
