#pragma once
#include <Arduino.h>
#include <time.h>
#include "Stats.h"

/**
 * Day/Night electricity tariff manager.
 *
 * Stores two prices and two hour boundaries in NVS and, when enabled,
 * automatically pushes the correct price into Stats every time the
 * active zone (day vs. night) changes.
 *
 * Call update() once per second from the main loop.
 */
class Tariff {
public:
    void begin(Stats& stats);       // load NVS, do initial price sync
    void resetNVS();

    // Called once per second – applies price to Stats when zone changes.
    void update();

    // ── Getters ─────────────────────────────────────────
    bool  isEnabled()      const { return _enabled; }
    float getDayPrice()    const { return _dayPrice; }
    float getNightPrice()  const { return _nightPrice; }
    uint8_t getDayStartHour()   const { return _dayStart; }
    uint8_t getNightStartHour() const { return _nightStart; }

    bool  isDayZone()      const;  // based on current RTC time
    float getActivePrice() const { return isDayZone() ? _dayPrice : _nightPrice; }

    // ── Setters (persist to NVS, immediately sync Stats if enabled) ──
    void setEnabled(bool v);
    void setDayPrice(float price);
    void setNightPrice(float price);
    void setDayStartHour(uint8_t h);
    void setNightStartHour(uint8_t h);

    String toJson() const;

private:
    Stats* _stats = nullptr;

    bool    _enabled    = false;
    float   _dayPrice   = 0.0f;
    float   _nightPrice = 0.0f;
    uint8_t _dayStart   = 7;
    uint8_t _nightStart = 23;

    bool _lastZone = true;  // true = day, false = night (tracks last applied zone)

    void saveNVS() const;
    void applyPrice();   // push activePrice to Stats unconditionally
};
