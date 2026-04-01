#include "Stats.h"
#include <Preferences.h>
#include "WebSerial.h"

static const char* NVS_NS       = "stats";
static const char* NVS_AT_HEAT  = "atHeatSec";
static const char* NVS_AT_SESS  = "atSessions";
static const char* NVS_AT_ENER  = "atEnergyWh";
static const char* NVS_PRICE    = "priceKWh4";
static const char* NVS_MO_ENER  = "moEnergyWh";
static const char* NVS_MO_MONTH = "moMonth";
static const char* NVS_MO_YEAR  = "moYear";
static const char* NVS_YR_ENER  = "yrEnergyWh";
static const char* NVS_YR_YEAR  = "yrYear";

// ─────────────────────────────────────────────────────────
void Stats::beginNVS() {
    Preferences p;
    p.begin(NVS_NS, true);
    _allTimeHeatingSec = p.getULong(NVS_AT_HEAT, 0);
    _allTimeSessions   = p.getULong(NVS_AT_SESS, 0);
    _allTimeEnergyKWh  = p.getULong(NVS_AT_ENER, 0) / 1000.0f;
    _pricePerKWh       = p.getULong(NVS_PRICE,   0) / 10000.0f;
    _nvsMoMonth        = (int16_t)p.getInt(NVS_MO_MONTH, -1);
    _nvsMoYear         = (int16_t)p.getInt(NVS_MO_YEAR,  -1);
    _nvsMoWh           = p.getULong(NVS_MO_ENER, 0);
    _nvsYrYear         = (int16_t)p.getInt(NVS_YR_YEAR,  -1);
    _nvsYrWh           = p.getULong(NVS_YR_ENER, 0);
    p.getBytes("weekLog", _weekLog, sizeof(_weekLog));
    p.end();
    webSerial.printf("[Stats] Loaded: %lu sessions, %lu s, %.3f kWh, price %.4f/kWh\n",
                  _allTimeSessions, _allTimeHeatingSec, _allTimeEnergyKWh, _pricePerKWh);
}

// ─────────────────────────────────────────────────────────
void Stats::resetNVS() {
    _allTimeHeatingSec = 0;
    _allTimeSessions   = 0;
    _allTimeEnergyKWh  = 0.0f;
    _monthEnergyKWh    = 0.0f;
    _yearEnergyKWh     = 0.0f;
    _thisMonth         = -1;
    _thisMonthYear     = -1;
    _thisYear          = -1;
    _nvsApplied        = false;
    _todayHeatingSec   = 0;
    _todaySessions     = 0;
    _todayEnergyKWh    = 0.0f;
    _head              = 0;
    _sessionCount      = 0;
    memset(_weekLog, 0, sizeof(_weekLog));
    _currentWday       = -1;
    saveToNVS();
    webSerial.println("[Stats] Reset");
}

// ─────────────────────────────────────────────────────────
void Stats::saveToNVS() const {
    Preferences p;
    p.begin(NVS_NS, false);
    p.putULong(NVS_AT_HEAT,  _allTimeHeatingSec);
    p.putULong(NVS_AT_SESS,  _allTimeSessions);
    p.putULong(NVS_AT_ENER,  (uint32_t)(_allTimeEnergyKWh  * 1000.0f));
    p.putULong(NVS_PRICE,    (uint32_t)(_pricePerKWh        * 10000.0f));
    p.putInt  (NVS_MO_MONTH, _thisMonth);
    p.putInt  (NVS_MO_YEAR,  _thisMonthYear);
    p.putULong(NVS_MO_ENER,  (uint32_t)(_monthEnergyKWh    * 1000.0f));
    p.putInt  (NVS_YR_YEAR,  _thisYear);
    p.putULong(NVS_YR_ENER,  (uint32_t)(_yearEnergyKWh     * 1000.0f));
    p.putBytes("weekLog", _weekLog, sizeof(_weekLog));
    p.end();
}

// ─────────────────────────────────────────────────────────
void Stats::update(bool relayOn, float waterTemp, float pzemEnergyKWh, bool pzemValid) {
    time_t now = time(nullptr);
    bool   haveTime = (now > 1000000000L);

    if (haveTime) {
        struct tm t;
        localtime_r(&now, &t);
        checkDayRollover(t);
    }

    if (!_wasOn && relayOn) {
        sessionStarted(waterTemp, pzemEnergyKWh, pzemValid, haveTime ? now : 0);
    } else if (_wasOn && !relayOn) {
        sessionEnded(waterTemp, pzemEnergyKWh, pzemValid);
    }

    _wasOn = relayOn;
}

// ─────────────────────────────────────────────────────────
void Stats::checkDayRollover(const struct tm& t) {
    int year  = t.tm_year + 1900;
    int month = t.tm_mon + 1;

    if (!_nvsApplied) {
        _nvsApplied    = true;
        _thisYear       = year;
        _thisMonth      = month;
        _thisMonthYear  = year;
        if (_nvsMoMonth == (int16_t)month && _nvsMoYear == (int16_t)year)
            _monthEnergyKWh = _nvsMoWh / 1000.0f;
        if (_nvsYrYear == (int16_t)year)
            _yearEnergyKWh  = _nvsYrWh / 1000.0f;
    }

    if (_thisYear != year) {
        _thisYear       = year;
        _yearEnergyKWh  = 0.0f;
        saveToNVS();
    }

    if (_thisMonthYear != year || _thisMonth != month) {
        _thisMonth      = month;
        _thisMonthYear  = year;
        _monthEnergyKWh = 0.0f;
        saveToNVS();
    }

    if (_todayYday == t.tm_yday && _todayYear == year) return;

    // Save outgoing day to weekly log before resetting counters
    if (_currentWday >= 0 && _todayDate[0] != '\0') {
        DayRecord& dr       = _weekLog[_currentWday];
        dr.heatingSec       = _todayHeatingSec;
        dr.energyWh         = (uint32_t)(_todayEnergyKWh * 1000.0f);
        dr.sessions         = (uint16_t)_todaySessions;
        strncpy(dr.date, _todayDate, sizeof(dr.date) - 1);
        dr.date[11]         = '\0';
        saveToNVS();
    }
    _currentWday     = t.tm_wday;
    _todayYday       = t.tm_yday;
    _todayYear       = year;
    _todayHeatingSec = 0;
    _todaySessions   = 0;
    _todayEnergyKWh  = 0.0f;
    snprintf(_todayDate, sizeof(_todayDate), "%04d-%02d-%02d",
             year, month, t.tm_mday);
}

// ─────────────────────────────────────────────────────────
void Stats::sessionStarted(float waterTemp, float pzemEnergyKWh, bool pzemValid, time_t epoch) {
    _sessionStartMs     = millis();
    _sessionStartEpoch  = epoch;
    _sessionStartTemp   = waterTemp;
    _sessionStartEnergy = pzemEnergyKWh;
    _sessionEnergyValid = pzemValid;
}

// ─────────────────────────────────────────────────────────
void Stats::sessionEnded(float waterTemp, float pzemEnergyKWh, bool pzemValid) {
    uint32_t durationSec = (millis() - _sessionStartMs) / 1000;

    float energy = 0.0f;
    if (_sessionEnergyValid && pzemValid && pzemEnergyKWh >= _sessionStartEnergy) {
        energy = pzemEnergyKWh - _sessionStartEnergy;
    }

    HeatingSession s;
    s.startEpoch  = (uint32_t)_sessionStartEpoch;
    s.durationSec = durationSec;
    s.startTemp   = _sessionStartTemp;
    s.endTemp     = waterTemp;
    s.energyKWh   = energy;
    pushSession(s);

    _todayHeatingSec   += durationSec;
    _todaySessions++;
    _todayEnergyKWh    += energy;
    _monthEnergyKWh    += energy;
    _yearEnergyKWh     += energy;
    _allTimeHeatingSec += durationSec;
    _allTimeSessions++;
    _allTimeEnergyKWh  += energy;
    saveToNVS();

    webSerial.printf("[Stats] Session: %lu s, %.3f kWh, %.1f→%.1f °C\n",
                  durationSec, energy, s.startTemp, s.endTemp);
}

// ─────────────────────────────────────────────────────────
void Stats::pushSession(const HeatingSession& s) {
    _sessions[_head] = s;
    _head = (_head + 1) % MAX_SESSIONS;
    if (_sessionCount < MAX_SESSIONS) _sessionCount++;
}

// ─────────────────────────────────────────────────────────
const HeatingSession& Stats::getSession(uint8_t idx) const {
    uint8_t realIdx = (_head + MAX_SESSIONS - 1 - idx) % MAX_SESSIONS;
    return _sessions[realIdx];
}

// ─────────────────────────────────────────────────────────
const DayRecord& Stats::getDayRecord(uint8_t wday) const {
    static const DayRecord empty = {};
    if (wday > 6) return empty;
    return _weekLog[wday];
}

// ─────────────────────────────────────────────────────────
uint32_t Stats::getActiveDurationSec() const {
    if (!_wasOn) return 0;
    return (millis() - _sessionStartMs) / 1000;
}

// ─────────────────────────────────────────────────────────
void Stats::setPricePerKWh(float price) {
    if (price < 0.0f) price = 0.0f;
    _pricePerKWh = price;
    saveToNVS();
    webSerial.printf("[Stats] Price set to %.4f/kWh\n", price);
}

// ─────────────────────────────────────────────────────────
static String fmtEpoch(uint32_t epoch) {
    if (epoch == 0) return "null";
    time_t t = (time_t)epoch;
    struct tm s;
    localtime_r(&t, &s);
    char buf[22];
    snprintf(buf, sizeof(buf), "\"%04d-%02d-%02dT%02d:%02d:%02d\"",
             s.tm_year + 1900, s.tm_mon + 1, s.tm_mday,
             s.tm_hour, s.tm_min, s.tm_sec);
    return String(buf);
}

static String fmtTemp(float v) {
    if (isnan(v)) return "null";
    char b[8];
    snprintf(b, sizeof(b), "%.1f", v);
    return String(b);
}

// ─────────────────────────────────────────────────────────
String Stats::toJson() const {
    String s;
    s.reserve(1200 + _sessionCount * 120);

    s += "{\"pricePerKWh\":";       s += String(_pricePerKWh, 4);
    s += ",";

    s += "\"today\":{\"date\":\"";
    s += (_todayDate[0] ? _todayDate : "unknown");
    s += "\",\"heatingTimeSec\":";  s += _todayHeatingSec;
    s += ",\"sessions\":";          s += _todaySessions;
    s += ",\"energyKWh\":";         s += String(_todayEnergyKWh, 3);
    s += ",\"cost\":";              s += String(_todayEnergyKWh * _pricePerKWh, 4);
    s += "},";

    s += "\"month\":{\"energyKWh\":"; s += String(_monthEnergyKWh, 3);
    s += ",\"cost\":";                s += String(_monthEnergyKWh * _pricePerKWh, 4);
    s += "},";

    s += "\"year\":{\"energyKWh\":";  s += String(_yearEnergyKWh, 3);
    s += ",\"cost\":";                s += String(_yearEnergyKWh * _pricePerKWh, 4);
    s += "},";

    s += "\"allTime\":{\"heatingTimeSec\":"; s += _allTimeHeatingSec;
    s += ",\"sessions\":";                   s += _allTimeSessions;
    s += ",\"energyKWh\":";                  s += String(_allTimeEnergyKWh, 3);
    s += ",\"cost\":";                       s += String(_allTimeEnergyKWh * _pricePerKWh, 4);
    s += "},";

    if (_wasOn) {
        s += "\"activeSession\":{\"durationSec\":"; s += getActiveDurationSec();
        s += ",\"startTemp\":";                     s += fmtTemp(_sessionStartTemp);
        s += "},";
    } else {
        s += "\"activeSession\":null,";
    }

    s += "\"log\":[";
    for (uint8_t i = 0; i < _sessionCount; i++) {
        if (i > 0) s += ",";
        const HeatingSession& h = getSession(i);
        s += "{\"start\":";       s += fmtEpoch(h.startEpoch);
        s += ",\"durationSec\":"; s += h.durationSec;
        s += ",\"startTemp\":";   s += fmtTemp(h.startTemp);
        s += ",\"endTemp\":";     s += fmtTemp(h.endTemp);
        s += ",\"energyKWh\":";   s += String(h.energyKWh, 3);
        s += ",\"cost\":";        s += String(h.energyKWh * _pricePerKWh, 4);
        s += "}";
    }
    s += "],";

    s += "\"week\":[";
    bool firstDay = true;
    for (uint8_t wd = 0; wd < 7; wd++) {
        const DayRecord& dr = _weekLog[wd];
        if (dr.date[0] == '\0') continue;
        if (!firstDay) s += ",";
        firstDay = false;
        float ekwh = dr.energyWh / 1000.0f;
        s += "{\"wday\":";       s += wd;
        s += ",\"date\":\"";     s += dr.date; s += "\"";
        s += ",\"heatingSec\":"; s += dr.heatingSec;
        s += ",\"sessions\":";   s += dr.sessions;
        s += ",\"energyKWh\":";  s += String(ekwh, 3);
        s += ",\"cost\":";       s += String(ekwh * _pricePerKWh, 4);
        s += "}";
    }
    s += "]}";

    return s;
}
