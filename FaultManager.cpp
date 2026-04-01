#include "FaultManager.h"
#include "PowerMeter.h"
#include "Config.h"
#include "WebSerial.h"
#include <esp_attr.h>

// ── Static storage ───────────────────────────────────────
FaultCode FaultManager::_code    = FaultCode::None;
String    FaultManager::_details = "";

uint32_t FaultManager::_tempNanSince   = 0;
bool     FaultManager::_tempWasValid   = false;
uint32_t FaultManager::_bodyNanSince   = 0;
bool     FaultManager::_bodyWasValid   = false;
bool     FaultManager::_bodyEverDetected = false;
uint32_t FaultManager::_relayOffSince  = 0;
bool     FaultManager::_relayWasOn     = false;
uint32_t FaultManager::_relayOnSince   = 0;
bool     FaultManager::_relayWasOnElem = false;

// RTC memory survives ESP.restart() but not power-cycle
static RTC_NOINIT_ATTR uint32_t rtcFaultMagic;
static RTC_NOINIT_ATTR bool     rtcWasFault;
static constexpr uint32_t RTC_MAGIC = 0xFA017ED1;

// ─────────────────────────────────────────────────────────
void FaultManager::raise(FaultCode code, const String& details) {
    if (_code != FaultCode::None) return;   // first fault wins

    _code    = code;
    _details = details;

    webSerial.printf("[FAULT] %s", codeToStr(code));
    if (details.length()) webSerial.printf(" – %s", details.c_str());
    webSerial.println();
}

// ─────────────────────────────────────────────────────────
void FaultManager::resetTimers() {
    uint32_t now = millis();
    _tempNanSince   = now;
    _tempWasValid   = false;
    _bodyNanSince   = now;
    _bodyWasValid   = false;
    _bodyEverDetected = false;
    _relayOffSince  = now;
    _relayWasOn     = false;
    _relayOnSince   = now;
    _relayWasOnElem = false;
}

// ─────────────────────────────────────────────────────────
void FaultManager::checkWaterTemp(float waterTemp, uint32_t now) {
    if (isFaulted()) return;

    if (isnan(waterTemp)) {
        if (_tempWasValid) {
            _tempNanSince = now;
            _tempWasValid = false;
        } else if (now - _tempNanSince >= TEMP_SENSOR_LOST_MS) {
            raise(FaultCode::TempSensorLost,
                "NaN for >" + String(TEMP_SENSOR_LOST_MS / 1000) + "s");
        }
    } else {
        _tempWasValid = true;
        if (waterTemp >= HEATER_FAULT_TEMP) {
            raise(FaultCode::OverTemperature,
                String(waterTemp, 1) + "C >= " + String(HEATER_FAULT_TEMP, 0) + "C");
        }
    }
}

// ─────────────────────────────────────────────────────────
void FaultManager::checkBodyTemp(float bodyTemp, uint32_t now) {
    if (isFaulted()) return;

    if (!isnan(bodyTemp) && bodyTemp >= BODY_FAULT_TEMP) {
        raise(FaultCode::BodyOverTemperature,
            String(bodyTemp, 1) + "C >= " + String(BODY_FAULT_TEMP, 0) + "C");
        return;
    }

    if (isnan(bodyTemp)) {
        if (_bodyWasValid) {
            _bodyNanSince = now;
            _bodyWasValid = false;
        } else if (_bodyEverDetected && (now - _bodyNanSince >= BODY_SENSOR_LOST_MS)) {
            raise(FaultCode::BodySensorLost,
                "NaN for >" + String(BODY_SENSOR_LOST_MS / 1000) + "s");
        }
    } else {
        _bodyWasValid     = true;
        _bodyEverDetected = true;
    }
}

// ─────────────────────────────────────────────────────────
void FaultManager::checkPower(const PowerData& p, bool relayOn, uint32_t now) {
    if (isFaulted()) return;

    if (relayOn) {
        _relayWasOn = true;
        if (!_relayWasOnElem) {
            _relayOnSince   = now;
            _relayWasOnElem = true;
        }
        if (p.valid && (now - _relayOnSince >= HEATER_ELEMENT_CHECK_MS)) {
            if (p.power < HEATER_MIN_POWER_W) {
                raise(FaultCode::HeaterElementFault,
                    String(p.power, 0) + "W with relay ON");
            }
            if (p.power > HEATER_MAX_POWER_W) {
                raise(FaultCode::OverCurrent,
                    String(p.power, 0) + "W > " + String(HEATER_MAX_POWER_W, 0) + "W");
            }
        }
    } else {
        _relayWasOnElem = false;
        if (_relayWasOn) {
            _relayOffSince = now;
            _relayWasOn    = false;
        }
        if (p.valid && (now - _relayOffSince >= RELAY_STUCK_DELAY_MS)
                    && p.power >= RELAY_STUCK_POWER_W) {
            raise(FaultCode::RelayStuckOn,
                String(p.power, 0) + "W with relay OFF");
        }
    }
}

// ─────────────────────────────────────────────────────────
void FaultManager::saveRebootReason(bool wasFault) {
    rtcFaultMagic = RTC_MAGIC;
    rtcWasFault   = wasFault;
}

bool FaultManager::previousBootFaulted() {
    if (rtcFaultMagic != RTC_MAGIC) return false;
    return rtcWasFault;
}

// ─────────────────────────────────────────────────────────
const char* FaultManager::codeToStr(FaultCode c) {
    switch (c) {
        case FaultCode::None:              return "OK";
        case FaultCode::DisplayInitFailed: return "DISPLAY INIT FAILED";
        case FaultCode::WiFiConnectFailed: return "WIFI CONNECT FAILED";
        case FaultCode::TempSensorLost:    return "TEMP SENSOR LOST";
        case FaultCode::OverTemperature:       return "OVER TEMPERATURE";
        case FaultCode::BodyOverTemperature:   return "BODY OVER TEMP";
        case FaultCode::RelayStuckOn:          return "RELAY STUCK ON";
        case FaultCode::BodySensorLost:        return "BODY SENSOR LOST";
        case FaultCode::HeaterElementFault:    return "ELEMENT FAULT";
        case FaultCode::OverCurrent:           return "OVERCURRENT";
        case FaultCode::InternalError:          return "INTERNAL ERROR";
        default:                           return "UNKNOWN FAULT";
    }
}
