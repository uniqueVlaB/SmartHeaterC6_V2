#include "Button.h"
#include "Config.h"
#include "WebSerial.h"

Button::Button(uint8_t pin, uint16_t debounceMs)
    : _pin(pin), _debounceMs(debounceMs) {}

void Button::begin() {
    pinMode(_pin, INPUT_PULLUP);
    delay(10);
    _raw        = digitalRead(_pin);
    _prevRaw    = _raw;
    _bootTime   = millis();
    _changeTime = millis();
    _state      = State::BootGrace;
    webSerial.printf("[Button] begin() pin=%d  reading=%s\n",
        _pin, _raw == LOW ? "LOW" : "HIGH");
}

void Button::tick() {
    _prevRaw = _raw;
    _raw     = digitalRead(_pin);

    if (_raw != _prevRaw) {
        _changeTime = millis();
    }

    bool stable = (millis() - _changeTime) >= _debounceMs;

    switch (_state) {

        case State::BootGrace:
            if (millis() - _bootTime >= 1000) {
                webSerial.println("[Button] Boot grace expired -> Idle");
                _changeTime  = millis();
                _requireHigh = (_raw == LOW);
                _state       = State::Idle;
            }
            break;

        case State::Idle:
            if (stable && _raw == HIGH) {
                _requireHigh = false;
            }
            if (stable && _raw == LOW && !_requireHigh) {
                webSerial.println("[Button] Press detected -> Held");
                _pressStart = millis();
                _state      = State::Held;
            }
            break;

        case State::Held:
            if (_raw == HIGH) {
                webSerial.println("[Button] Short press fired");
                _shortEvent = true;
                _state      = State::Idle;
            } else if ((millis() - _pressStart) >= BUTTON_LONG_PRESS_MS) {
                webSerial.println("[Button] Long press fired");
                _longEvent = true;
                _state     = State::LongFired;
            }
            break;

        case State::LongFired:
            if (_raw == HIGH) {
                _state = State::Idle;
            }
            break;
    }
}

bool Button::wasPressed() {
    if (_shortEvent) { _shortEvent = false; return true; }
    return false;
}

bool Button::wasLongPressed() {
    if (_longEvent) { _longEvent = false; return true; }
    return false;
}
