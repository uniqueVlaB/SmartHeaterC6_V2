#pragma once
#include <Arduino.h>
#include <time.h>
#include "Config.h"

class TimeSync {
public:
    void begin();
    void update();
    bool getLocalTime(struct tm& t) const;
    String getTimeString() const;
    String getDateTimeString() const;
    bool isSynced() const { return _synced; }

private:
    bool      _synced   = false;
    uint32_t  _lastSync = 0;
    void doSync();
};
