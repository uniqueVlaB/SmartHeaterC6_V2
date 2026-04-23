#pragma once
#include <Arduino.h>

class Button {
public:
    explicit Button(uint8_t pin, uint16_t debounceMs = 50);
    void begin();
    void tick();
    bool wasPressed();
    bool wasLongPressed();

private:
    enum class State : uint8_t {
        BootGrace,
        Idle,
        Debounce,
        Held,
        LongFired,
    };

    uint8_t  _pin;
    uint16_t _debounceMs;
    State    _state      = State::Idle;
    bool     _raw        = HIGH;
    bool     _prevRaw    = HIGH;
    uint32_t _changeTime = 0;
    uint32_t _pressStart = 0;
    uint32_t _bootTime   = 0;
    bool     _shortEvent = false;
    bool     _longEvent  = false;
    bool     _requireHigh = true;
};
