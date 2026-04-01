#pragma once
#include <FastLED.h>

enum class LedStatus : uint8_t {
    Off,
    Idle,
    Heating,
    Error,
    Connecting,
    Fault
};

class StatusLed {
public:
    void begin();
    void set(LedStatus status);
    void tick();

    void setEnabled(bool en) { _userEnabled = en; }
    bool isEnabled() const   { return _userEnabled; }

private:
    CRGB      _leds[1];
    LedStatus _status      = LedStatus::Off;
    uint32_t  _lastPulse   = 0;
    bool      _pulseOn     = false;
    bool      _userEnabled = true;
};
