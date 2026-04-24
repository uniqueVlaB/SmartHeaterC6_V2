#pragma once
#include <Arduino.h>
#include "Config.h"

class HeaterRelay {
public:
    explicit HeaterRelay(uint8_t pin);
    void begin();
    void on();
    void off();
    bool isOn() const;

private:
    uint8_t  _pin;
    bool     _state      = false;
    uint32_t _lastSwitch = 0;  // millis() of last state change
};
