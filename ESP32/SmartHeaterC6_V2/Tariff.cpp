#include "Tariff.h"
#include <Preferences.h>
#include "WebSerial.h"

static const char* NVS_NS      = "tariff";
static const char* NVS_ENABLED = "enabled";
static const char* NVS_DAY_P   = "dayPrice4";   // stored as uint32 * 10000
static const char* NVS_NIGHT_P = "nightPrice4";
static const char* NVS_DAY_H   = "dayStart";
static const char* NVS_NIGHT_H = "nightStart";

// ─────────────────────────────────────────────────────────
void Tariff::begin(Stats& stats) {
    _stats = &stats;

    Preferences p;
    p.begin(NVS_NS, true);
    _enabled    = p.getBool(NVS_ENABLED, false);
    _dayPrice   = p.getULong(NVS_DAY_P,   0) / 10000.0f;
    _nightPrice = p.getULong(NVS_NIGHT_P, 0) / 10000.0f;
    _dayStart   = (uint8_t)p.getUChar(NVS_DAY_H,   7);
    _nightStart = (uint8_t)p.getUChar(NVS_NIGHT_H, 23);
    p.end();

    _lastZone = isDayZone();

    if (_enabled) applyPrice();

    webSerial.printf("[Tariff] Loaded: enabled=%d day=%.4f night=%.4f dayStart=%d nightStart=%d\n",
                     _enabled, _dayPrice, _nightPrice, _dayStart, _nightStart);
}

// ─────────────────────────────────────────────────────────
void Tariff::resetNVS() {
    _enabled    = false;
    _dayPrice   = 0.0f;
    _nightPrice = 0.0f;
    _dayStart   = 7;
    _nightStart = 23;
    saveNVS();
    webSerial.println("[Tariff] Reset");
}

// ─────────────────────────────────────────────────────────
void Tariff::update() {
    if (!_enabled) return;
    bool zone = isDayZone();
    if (zone != _lastZone) {
        _lastZone = zone;
        applyPrice();
        webSerial.printf("[Tariff] Zone changed → %s (%.4f/kWh)\n",
                         zone ? "day" : "night", getActivePrice());
    }
}

// ─────────────────────────────────────────────────────────
bool Tariff::isDayZone() const {
    time_t now = time(nullptr);
    if (now < 1000000000L) return true;  // no RTC yet → assume day
    struct tm t;
    localtime_r(&now, &t);
    uint8_t h = (uint8_t)t.tm_hour;

    if (_dayStart < _nightStart) {
        return h >= _dayStart && h < _nightStart;
    } else {
        // e.g. dayStart=23, nightStart=7: day wraps midnight
        return h >= _dayStart || h < _nightStart;
    }
}

// ─────────────────────────────────────────────────────────
void Tariff::setEnabled(bool v) {
    _enabled = v;
    saveNVS();
    if (v) {
        _lastZone = isDayZone();
        applyPrice();
    }
    webSerial.printf("[Tariff] %s\n", v ? "enabled" : "disabled");
}

void Tariff::setDayPrice(float price) {
    if (price < 0) price = 0;
    _dayPrice = price;
    saveNVS();
    if (_enabled && isDayZone()) applyPrice();
}

void Tariff::setNightPrice(float price) {
    if (price < 0) price = 0;
    _nightPrice = price;
    saveNVS();
    if (_enabled && !isDayZone()) applyPrice();
}

void Tariff::setDayStartHour(uint8_t h) {
    _dayStart = h % 24;
    saveNVS();
    if (_enabled) {
        _lastZone = isDayZone();
        applyPrice();
    }
}

void Tariff::setNightStartHour(uint8_t h) {
    _nightStart = h % 24;
    saveNVS();
    if (_enabled) {
        _lastZone = isDayZone();
        applyPrice();
    }
}

// ─────────────────────────────────────────────────────────
void Tariff::applyPrice() {
    if (!_stats) return;
    float price = getActivePrice();
    _stats->setPricePerKWh(price);
    webSerial.printf("[Tariff] Applied %.4f/kWh (%s zone)\n",
                     price, isDayZone() ? "day" : "night");
}

// ─────────────────────────────────────────────────────────
void Tariff::saveNVS() const {
    Preferences p;
    p.begin(NVS_NS, false);
    p.putBool(NVS_ENABLED, _enabled);
    p.putULong(NVS_DAY_P,   (uint32_t)(_dayPrice   * 10000.0f));
    p.putULong(NVS_NIGHT_P, (uint32_t)(_nightPrice * 10000.0f));
    p.putUChar(NVS_DAY_H,   _dayStart);
    p.putUChar(NVS_NIGHT_H, _nightStart);
    p.end();
}

// ─────────────────────────────────────────────────────────
String Tariff::toJson() const {
    char buf[200];
    snprintf(buf, sizeof(buf),
        "{\"enabled\":%s,"
        "\"dayPrice\":%.4f,"
        "\"nightPrice\":%.4f,"
        "\"dayStartHour\":%d,"
        "\"nightStartHour\":%d,"
        "\"activeZone\":\"%s\","
        "\"activePrice\":%.4f}",
        _enabled ? "true" : "false",
        _dayPrice,
        _nightPrice,
        _dayStart,
        _nightStart,
        isDayZone() ? "day" : "night",
        getActivePrice());
    return String(buf);
}
