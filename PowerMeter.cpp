#include "PowerMeter.h"
#include "WebSerial.h"

PowerMeter::PowerMeter(uint8_t rxPin, uint8_t txPin)
    : _rx(rxPin), _tx(txPin), _serial(1) {}   // UART1

void PowerMeter::begin() {
    _pzem = new PZEM004Tv30(_serial, _rx, _tx);
    webSerial.println("[PZEM] Initialized on UART1");
}

void PowerMeter::requestReading() {
    if (!_pzem) return;

    float v = _pzem->voltage();
    float c = _pzem->current();
    float p = _pzem->power();
    float e = _pzem->energy();
    float f = _pzem->frequency();
    float pf = _pzem->pf();

    if (!isnan(v)) {
        _data.voltage   = v;
        _data.current   = c;
        _data.power     = p;
        _data.energy    = e;
        _data.frequency = f;
        _data.pf        = pf;
        _data.valid     = true;
        _consecutiveFailures = 0;
    } else {
        _data.valid = false;
        if (_consecutiveFailures < 255) _consecutiveFailures++;
    }
}

const PowerData& PowerMeter::getData() const {
    return _data;
}

void PowerMeter::resetEnergy() {
    if (_pzem) _pzem->resetEnergy();
}
