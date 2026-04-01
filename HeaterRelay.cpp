#include "HeaterRelay.h"

HeaterRelay::HeaterRelay(uint8_t pin) : _pin(pin) {}

void HeaterRelay::begin() {
    pinMode(_pin, OUTPUT);
    off();
}

void HeaterRelay::on() {
    if (_state) return;  // already on
    uint32_t now = millis();
    if (now - _lastSwitch < RELAY_MIN_SWITCH_MS) return;  // anti-chatter guard
    _state = true;
    _lastSwitch = now;
    digitalWrite(_pin, HIGH);
}

void HeaterRelay::off() {
    if (!_state && _lastSwitch != 0) return;  // already off (allow first call from begin())
    uint32_t now = millis();
    if (_lastSwitch != 0 && (now - _lastSwitch < RELAY_MIN_SWITCH_MS)) return;
    _state = false;
    _lastSwitch = now;
    digitalWrite(_pin, LOW);
}

bool HeaterRelay::isOn() const {
    return _state;
}
