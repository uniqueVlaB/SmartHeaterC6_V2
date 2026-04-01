#include "Scheduler.h"
#include <Preferences.h>
#include "WebSerial.h"

static const char* NVS_NS      = "scheduler";
static const char* NVS_SLOTS   = "slots";
static const char* NVS_COUNT   = "count";
static const char* NVS_NEXT_ID = "nextId";

static const char* DAY_NAMES[] = { "Mon","Tue","Wed","Thu","Fri","Sat","Sun" };

// ─────────────────────────────────────────────────────────
uint8_t Scheduler::tmDayBit(int tm_wday) {
    return (uint8_t)(1u << ((tm_wday + 6) % 7));
}

// ─────────────────────────────────────────────────────────
void Scheduler::begin() {
    loadFromNVS();
    if (_count == 0) {
        loadDefaults();
    }
    webSerial.printf("[Scheduler] Loaded %d slot(s)\n", _count);
}

// ─────────────────────────────────────────────────────────
bool Scheduler::isActive(const struct tm& t, float& outTarget) const {
    const ScheduleSlot* dummy = nullptr;
    return isActive(t, outTarget, dummy);
}

bool Scheduler::isActive(const struct tm& t, float& outTarget, const ScheduleSlot*& outSlot) const {
    uint16_t nowMin = (uint16_t)(t.tm_hour * 60 + t.tm_min);
    uint8_t  dayBit = tmDayBit(t.tm_wday);

    outSlot = nullptr;
    for (uint8_t i = 0; i < _count; i++) {
        const ScheduleSlot& s = _slots[i];
        if (!s.enabled)           continue;
        if (!(s.dayMask & dayBit)) continue;

        bool inWindow;
        if (s.fromMin <= s.toMin) {
            inWindow = (nowMin >= s.fromMin && nowMin < s.toMin);
        } else {
            inWindow = (nowMin >= s.fromMin || nowMin < s.toMin);
        }

        if (inWindow) {
            outTarget = s.target;
            outSlot   = &s;
            return true;
        }
    }
    return false;
}

// ─────────────────────────────────────────────────────────
bool Scheduler::addSlot(uint8_t dayMask, uint16_t fromMin, uint16_t toMin,
                        float target, bool enabled) {
    if (_count >= SCHEDULER_MAX_SLOTS)  return false;
    if (dayMask == 0)                   return false;
    if (fromMin >= 1440 || toMin >= 1440) return false;
    if (fromMin == toMin)               return false;

    ScheduleSlot& s = _slots[_count++];
    s.id      = _nextId++;
    s.dayMask = dayMask;
    s.fromMin = fromMin;
    s.toMin   = toMin;
    s.target  = target;
    s.enabled = enabled ? 1 : 0;

    saveToNVS();
    webSerial.printf("[Scheduler] Added slot %d (%s – %02d:%02d→%02d:%02d)\n",
                  s.id, target > 0 ? String(target, 1).c_str() : "default°C",
                  fromMin / 60, fromMin % 60, toMin / 60, toMin % 60);
    return true;
}

// ─────────────────────────────────────────────────────────
bool Scheduler::removeSlot(uint8_t id) {
    for (uint8_t i = 0; i < _count; i++) {
        if (_slots[i].id == id) {
            _slots[i] = _slots[--_count];
            memset(&_slots[_count], 0, sizeof(ScheduleSlot));
            saveToNVS();
            webSerial.printf("[Scheduler] Removed slot %d\n", id);
            return true;
        }
    }
    return false;
}

// ─────────────────────────────────────────────────────────
bool Scheduler::setEnabled(uint8_t id, bool en) {
    for (uint8_t i = 0; i < _count; i++) {
        if (_slots[i].id == id) {
            _slots[i].enabled = en ? 1 : 0;
            saveToNVS();
            webSerial.printf("[Scheduler] Slot %d %s\n", id, en ? "enabled" : "disabled");
            return true;
        }
    }
    return false;
}

// ─────────────────────────────────────────────────────────
bool Scheduler::editSlot(uint8_t id, int dayMask, int fromMin, int toMin, float target) {
    for (uint8_t i = 0; i < _count; i++) {
        if (_slots[i].id == id) {
            if (dayMask >= 0) _slots[i].dayMask = (uint8_t)dayMask;
            if (fromMin >= 0) _slots[i].fromMin  = (uint16_t)fromMin;
            if (toMin   >= 0) _slots[i].toMin    = (uint16_t)toMin;
            if (target  >= 0) _slots[i].target   = target;
            saveToNVS();
            webSerial.printf("[Scheduler] Edited slot %d\n", id);
            return true;
        }
    }
    return false;
}

// ─────────────────────────────────────────────────────────
void Scheduler::clear() {
    _count  = 0;
    _nextId = 1;
    memset(_slots, 0, sizeof(_slots));
    saveToNVS();
    webSerial.println("[Scheduler] Cleared all slots");
}

// ─────────────────────────────────────────────────────────
void Scheduler::resetNVS() {
    Preferences prefs;
    prefs.begin(NVS_NS, false);
    prefs.clear();
    prefs.end();
    _count  = 0;
    _nextId = 1;
    memset(_slots, 0, sizeof(_slots));
    loadDefaults();
    webSerial.println("[Scheduler] NVS reset – defaults reloaded");
}

// ─────────────────────────────────────────────────────────
String Scheduler::toJson() const {
    String json;
    json.reserve(128 * _count + 4);
    json = "[";
    for (uint8_t i = 0; i < _count; i++) {
        const ScheduleSlot& s = _slots[i];
        if (i > 0) json += ",";
        json += "{";
        json += "\"id\":"      + String(s.id)      + ",";
        json += "\"dayMask\":" + String(s.dayMask) + ",";
        json += "\"days\":[";
        bool first = true;
        for (uint8_t d = 0; d < 7; d++) {
            if (s.dayMask & (1u << d)) {
                if (!first) json += ",";
                json += "\"";
                json += DAY_NAMES[d];
                json += "\"";
                first = false;
            }
        }
        char from[6], to[6];
        snprintf(from, sizeof(from), "%02d:%02d", s.fromMin / 60, s.fromMin % 60);
        snprintf(to,   sizeof(to),   "%02d:%02d", s.toMin   / 60, s.toMin   % 60);
        json += "],";
        json += "\"from\":\"";   json += from; json += "\",";
        json += "\"to\":\"";     json += to;   json += "\",";
        if (s.target > 0) json += "\"target\":"  + String(s.target, 1) + ",";
        else               json += "\"target\":null,";
        json += "\"enabled\":" + String(s.enabled ? "true" : "false");
        json += "}";
    }
    json += "]";
    return json;
}

// ─────────────────────────────────────────────────────────
void Scheduler::loadFromNVS() {
    Preferences prefs;
    prefs.begin(NVS_NS, true);

    _count  = prefs.getUChar(NVS_COUNT,   0);
    _nextId = prefs.getUChar(NVS_NEXT_ID, 1);
    if (_count > SCHEDULER_MAX_SLOTS) _count = 0;

    size_t expected = sizeof(ScheduleSlot) * SCHEDULER_MAX_SLOTS;
    size_t got      = prefs.getBytesLength(NVS_SLOTS);
    if (got == expected) {
        prefs.getBytes(NVS_SLOTS, _slots, expected);
    } else {
        _count  = 0;
        _nextId = 1;
        memset(_slots, 0, sizeof(_slots));
    }
    prefs.end();
}

// ─────────────────────────────────────────────────────────
void Scheduler::saveToNVS() const {
    Preferences prefs;
    prefs.begin(NVS_NS, false);
    prefs.putUChar(NVS_COUNT,   _count);
    prefs.putUChar(NVS_NEXT_ID, _nextId);
    prefs.putBytes(NVS_SLOTS,   _slots, sizeof(ScheduleSlot) * SCHEDULER_MAX_SLOTS);
    prefs.end();
}

// ─────────────────────────────────────────────────────────
void Scheduler::loadDefaults() {
    webSerial.println("[Scheduler] No saved schedule – loading defaults");
    addSlot(DAY_ALL,  6 * 60, 10 * 60, 70.0f);
    addSlot(DAY_ALL, 10 * 60, 16 * 60, 55.0f);
    addSlot(DAY_ALL, 16 * 60, 22 * 60, 70.0f);
}
