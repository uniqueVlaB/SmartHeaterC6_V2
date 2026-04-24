#include "TempSensors.h"
#include "WebSerial.h"

TempSensors::TempSensors(uint8_t pin)
    : _oneWire(pin), _sensors(&_oneWire) {}

void TempSensors::begin() {
    _sensors.begin();
    _sensors.setResolution(12);
    _sensors.setWaitForConversion(false);
    _bootTime = millis();
    webSerial.printf("[Temp] Found %d sensor(s) on OneWire bus\n", _sensors.getDeviceCount());
    printAddresses();
}

bool TempSensors::isValidReading(float t) const {
    if (t == DEVICE_DISCONNECTED_C) return false;
    if (t < TEMP_MIN_VALID || t > TEMP_MAX_VALID) return false;

    // Reject DS18B20 power-on-reset artefact (exactly 85.0°C) within boot window
    if (t == TEMP_POR_VALUE && (millis() - _bootTime < TEMP_POR_REJECT_WINDOW_MS)) {
        return false;
    }
    return true;
}

void TempSensors::requestReadings() {
    if (_conversionRequested) {
        if (_sensors.getDeviceCount() >= 1) {
            float t = _sensors.getTempCByIndex(0);
            if (isValidReading(t)) {
                _bodyTemp = t;
                _bodyFailCount = 0;
            } else {
                if (_bodyFailCount < 255) _bodyFailCount++;
                if (_bodyFailCount >= 3) _bodyTemp = NAN;
            }
        }
        if (_sensors.getDeviceCount() >= 2) {
            float t = _sensors.getTempCByIndex(1);
            if (isValidReading(t)) {
                _waterTemp = t;
                _waterFailCount = 0;
            } else {
                if (_waterFailCount < 255) _waterFailCount++;
                if (_waterFailCount >= 3) _waterTemp = NAN;
            }
        }
    }

    _sensors.requestTemperatures();
    _conversionRequested = true;
}

float TempSensors::getBodyTemp() const {
    return _bodyTemp;
}

float TempSensors::getWaterTemp() const {
    return _waterTemp;
}

uint8_t TempSensors::getSensorCount() {
    return _sensors.getDeviceCount();
}

void TempSensors::printAddresses() {
    DeviceAddress addr;
    for (uint8_t i = 0; i < _sensors.getDeviceCount(); i++) {
        if (_sensors.getAddress(addr, i)) {
            webSerial.printf("[Temp] Sensor %d address: ", i);
            for (uint8_t j = 0; j < 8; j++) {
                webSerial.printf("%02X", addr[j]);
            }
            webSerial.println();
        }
    }
}
