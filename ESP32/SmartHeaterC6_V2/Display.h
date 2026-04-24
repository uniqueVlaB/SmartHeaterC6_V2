#pragma once
#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>
#include "FaultManager.h"
#include "HeaterController.h"

struct DisplayData {
    float        waterTemp;
    float        bodyTemp;
    bool         heaterOn;
    float        effectiveTarget;
    float        maxTarget;
    float        boostTarget;
    float        powerW;
    float        voltage;
    float        current;
    float        energyKWh;
    float        frequency;
    float        pf;
    uint32_t     pauseRemaining;
    HeaterReason reason;
    uint16_t     schedFrom;
    uint16_t     schedTo;
    int8_t       rssi;
    bool         timeSynced;
    float        todayEnergyKWh;
    char         timeStr[9];
    char         ip[16];
};

class Display {
public:
    Display(uint8_t sda, uint8_t scl, uint8_t addr = 0x3C);
    bool begin();
    bool isInitialized() const { return _initialized; }
    void showSplash();
    void showStatus(const DisplayData& data);
    void showFault(FaultCode code, const String& details);
    void wake();
    void sleep();
    bool isAwake() const;
    void checkTimeout(uint32_t timeoutMs);

private:
    uint8_t _sda, _scl, _addr;
    Adafruit_SH1107 _oled;
    bool    _initialized = false;
    bool    _awake      = true;
    uint32_t _lastWake  = 0;
    bool    _ipShown    = false;
};
