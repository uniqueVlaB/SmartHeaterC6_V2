#include "StatusLed.h"
#include "Config.h"

void StatusLed::begin() {
    FastLED.addLeds<WS2812, PIN_LED_WS2812, GRB>(_leds, 1);
    FastLED.setBrightness(30);
    _leds[0] = CRGB::Black;
    FastLED.show();
}

void StatusLed::set(LedStatus status) {
    _status = status;

    // Fault always overrides user LED enable/disable
    if (!_userEnabled && status != LedStatus::Fault && status != LedStatus::Connecting) {
        _leds[0] = CRGB::Black;
        FastLED.show();
        return;
    }

    switch (status) {
        case LedStatus::Off:       _leds[0] = CRGB::Black;      break;
        case LedStatus::Idle:      _leds[0] = CRGB(0, 40, 0);   break;
        case LedStatus::Heating:   _leds[0] = CRGB(255, 80, 0); break;
        case LedStatus::Error:     _leds[0] = CRGB::Red;        break;
        case LedStatus::Connecting:_leds[0] = CRGB::Blue;       break;
        case LedStatus::Fault:     _leds[0] = CRGB::Red;        break;
    }
    FastLED.show();
}

void StatusLed::tick() {
    if (_status == LedStatus::Connecting) {
        if (millis() - _lastPulse >= 500) {
            _lastPulse = millis();
            _pulseOn = !_pulseOn;
            _leds[0] = _pulseOn ? CRGB::Blue : CRGB::Black;
            FastLED.show();
        }
        return;
    }

    if (_status == LedStatus::Fault) {
        if (millis() - _lastPulse >= 250) {
            _lastPulse = millis();
            _pulseOn = !_pulseOn;
            _leds[0] = _pulseOn ? CRGB::Red : CRGB::Black;
            FastLED.show();
        }
    }
}
