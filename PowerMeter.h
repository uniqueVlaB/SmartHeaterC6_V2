#pragma once
#include <Arduino.h>
#include <PZEM004Tv30.h>

struct PowerData {
    float voltage   = 0;
    float current   = 0;
    float power     = 0;
    float energy    = 0;
    float frequency = 0;
    float pf        = 0;
    bool  valid     = false;
};

class PowerMeter {
public:
    PowerMeter(uint8_t rxPin, uint8_t txPin);
    void begin();
    void requestReading();
    const PowerData& getData() const;
    void resetEnergy();
    uint8_t getConsecutiveFailures() const { return _consecutiveFailures; }

private:
    uint8_t   _rx, _tx;
    HardwareSerial _serial;
    PZEM004Tv30*   _pzem = nullptr;
    PowerData      _data;
    uint8_t        _consecutiveFailures = 0;
};
