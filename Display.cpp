#include "Display.h"
#include "WebSerial.h"

Display::Display(uint8_t sda, uint8_t scl, uint8_t addr)
    : _sda(sda), _scl(scl), _addr(addr),
      _oled(128, 128, &Wire, -1, 400000UL, 100000UL) {}

bool Display::begin() {
    Wire.begin(_sda, _scl);

    webSerial.printf("[Display] I2C scan on SDA=%d SCL=%d:\n", _sda, _scl);
    bool anyFound = false;
    for (uint8_t addr = 1; addr < 127; addr++) {
        Wire.beginTransmission(addr);
        if (Wire.endTransmission() == 0) {
            webSerial.printf("[Display]   found device at 0x%02X\n", addr);
            anyFound = true;
        }
    }
    if (!anyFound) webSerial.println("[Display]   no I2C devices found");

    delay(100);
    if (!_oled.begin(_addr, true)) {
        webSerial.printf("[Display] SH1107 not responding at 0x%02X\n", _addr);
        return false;
    }
    _oled.setRotation(1);
    _oled.clearDisplay();
    _oled.display();
    _lastWake    = millis();
    _initialized = true;
    webSerial.printf("[Display] OK at 0x%02X\n", _addr);
    return true;
}

void Display::showSplash() {
    if (!_initialized) return;
    _oled.clearDisplay();
    _oled.setTextSize(3);
    _oled.setTextColor(SH110X_WHITE);
    _oled.setCursor(0, 10);
    _oled.println("Smart");
    _oled.println("Heater");
    _oled.setTextSize(1);
    _oled.println();
    _oled.println("  Connecting WiFi...");
    _oled.display();
}

void Display::showStatus(const DisplayData& d) {
    if (!_initialized || !_awake) return;

    _oled.clearDisplay();
    _oled.setTextColor(SH110X_WHITE);

    // Row 1: reason + RSSI bars
    _oled.setCursor(0, 0);
    _oled.setTextSize(1);
    _oled.print(heaterReasonStr(d.reason));
    if (d.rssi != 0) {
        uint8_t bars = 0;
        if      (d.rssi > -55) bars = 4;
        else if (d.rssi > -67) bars = 3;
        else if (d.rssi > -78) bars = 2;
        else if (d.rssi > -89) bars = 1;
        for (uint8_t i = 0; i < 4; i++) {
            uint8_t h = (i + 1) * 3;
            uint8_t x = 104 + i * 6;
            uint8_t y = 8 - h;
            if (i < bars) _oled.fillRect(x, y, 4, h, SH110X_WHITE);
            else          _oled.drawRect(x, y, 4, h, SH110X_WHITE);
        }
    }

    // Row 2: targets + body temp
    _oled.setCursor(0, 10);
    _oled.setTextSize(1);
    _oled.printf("Set:%.0f Max:%.0f", d.effectiveTarget, d.maxTarget);
    if (!isnan(d.bodyTemp)) {
        _oled.setCursor(84, 10);
        _oled.printf("B:%.1f", d.bodyTemp);
    }

    _oled.drawFastHLine(0, 20, 128, SH110X_WHITE);

    // Row 3: water temp BIG
    _oled.setCursor(0, 22);
    _oled.setTextSize(3);
    if (!isnan(d.waterTemp)) _oled.printf("%.1f", d.waterTemp);
    else                     _oled.print("--.-");
    int16_t dx = _oled.getCursorX();
    _oled.drawCircle(dx + 4, 25, 3, SH110X_WHITE);
    _oled.setTextSize(2);
    _oled.setCursor(dx + 10, 30);
    _oled.print("C");

    _oled.drawFastHLine(0, 49, 128, SH110X_WHITE);

    // Row 4: schedule / pause / boost / time
    _oled.setCursor(0, 51);
    _oled.setTextSize(1);
    if (d.pauseRemaining > 0) {
        uint32_t m = d.pauseRemaining / 60;
        uint32_t s = d.pauseRemaining % 60;
        _oled.printf("PAUSED %lu:%02lu", m, s);
    } else if (d.reason == HeaterReason::Schedule) {
        _oled.printf("%02d:%02d-%02d:%02d",
                     d.schedFrom / 60, d.schedFrom % 60,
                     d.schedTo   / 60, d.schedTo   % 60);
    } else if (d.boostTarget > 0) {
        _oled.printf("BOOST -> %.0fC", d.boostTarget);
    }
    _oled.setCursor(80, 51);
    _oled.print(d.timeStr);

    // Row 5: power
    _oled.setCursor(0, 63);
    _oled.setTextSize(1);
    _oled.printf("%.0fW  %.0fV  %.2fA  %.0fHz", d.powerW, d.voltage, d.current, d.frequency);

    _oled.drawFastHLine(0, 73, 128, SH110X_WHITE);

    // Row 6: IP once, then today's energy bigger
    if (!_ipShown) {
        _oled.setCursor(0, 75);
        _oled.setTextSize(1);
        _oled.printf("IP: %s", d.ip);
    } else {
        _oled.setCursor(0, 75);
        _oled.setTextSize(2);
        _oled.printf("%.3f kWh", d.todayEnergyKWh);
    }

    _oled.display();
}

void Display::wake() {
    if (!_initialized) return;
    _awake = true;
    _lastWake = millis();
    _oled.oled_command(SH110X_DISPLAYON);
}

void Display::sleep() {
    if (!_initialized) return;
    _awake = false;
    _oled.oled_command(SH110X_DISPLAYOFF);
}

bool Display::isAwake() const {
    return _awake;
}

void Display::checkTimeout(uint32_t timeoutMs) {
    if (!_initialized) return;
    if (_awake && (millis() - _lastWake >= timeoutMs)) {
        _ipShown = true;
        sleep();
    }
}

void Display::showFault(FaultCode code, const String& details) {
    if (!_initialized) return;
    wake();

    _oled.clearDisplay();
    _oled.setTextColor(SH110X_WHITE);

    _oled.fillRect(0, 0, 128, 14, SH110X_WHITE);
    _oled.setTextColor(SH110X_BLACK);
    _oled.setTextSize(1);
    _oled.setCursor(2, 3);
    _oled.print("!!! FAULT !!!");

    _oled.setTextColor(SH110X_WHITE);
    _oled.setTextSize(1);
    _oled.setCursor(0, 20);
    _oled.println(FaultManager::codeToStr(code));

    _oled.setCursor(0, 36);
    _oled.setTextSize(1);
    if (details.length()) {
        _oled.println(details);
    }

    _oled.setCursor(0, 110);
    _oled.setTextSize(1);
    _oled.print("Power-cycle to reset");

    _oled.display();
}
