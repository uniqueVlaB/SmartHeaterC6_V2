#include "TimeSync.h"
#include <esp_sntp.h>
#include "WebSerial.h"

void TimeSync::begin() {
    configTzTime(NTP_TIMEZONE, NTP_SERVER1, NTP_SERVER2);
    _lastSync = millis();
    _synced   = false;
    webSerial.println("[NTP] Sync initiated (" NTP_SERVER1 ")");
}

void TimeSync::update() {
    if (!_synced && sntp_get_sync_status() == SNTP_SYNC_STATUS_COMPLETED) {
        _synced = true;
        webSerial.printf("[NTP] Synced – %s\n", getDateTimeString().c_str());
    }

    if (millis() - _lastSync >= NTP_SYNC_INTERVAL_MS) {
        doSync();
    }
}

void TimeSync::doSync() {
    _lastSync = millis();
    sntp_restart();
    webSerial.println("[NTP] Periodic re-sync triggered");
}

bool TimeSync::getLocalTime(struct tm& t) const {
    time_t now;
    time(&now);
    localtime_r(&now, &t);
    return t.tm_year > 70;
}

String TimeSync::getTimeString() const {
    struct tm t;
    if (!getLocalTime(t)) return "--:--:--";
    char buf[9];
    snprintf(buf, sizeof(buf), "%02d:%02d:%02d", t.tm_hour, t.tm_min, t.tm_sec);
    return String(buf);
}

String TimeSync::getDateTimeString() const {
    struct tm t;
    if (!getLocalTime(t)) return "not synced";
    char buf[20];
    snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d",
             t.tm_year + 1900, t.tm_mon + 1, t.tm_mday,
             t.tm_hour, t.tm_min, t.tm_sec);
    return String(buf);
}
