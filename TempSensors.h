#pragma once
#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include "Config.h"

class TempSensors {
public:
    explicit TempSensors(uint8_t pin);
    void  begin();
    void  requestReadings();
    float getBodyTemp()  const;
    float getWaterTemp() const;
    uint8_t getSensorCount();
    void printAddresses();

    uint8_t getWaterFailCount() const { return _waterFailCount; }
    uint8_t getBodyFailCount()  const { return _bodyFailCount;  }

private:
    OneWire          _oneWire;
    DallasTemperature _sensors;
    float   _bodyTemp  = NAN;
    float   _waterTemp = NAN;
    bool    _conversionRequested = false;
    uint32_t _bootTime = 0;

    uint8_t _waterFailCount = 0;
    uint8_t _bodyFailCount  = 0;

    bool isValidReading(float t) const;
};
