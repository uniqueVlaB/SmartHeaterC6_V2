#pragma once
#include <Arduino.h>
#include <time.h>

struct HeatingSession {
    uint32_t startEpoch;
    uint32_t durationSec;
    float    startTemp;
    float    endTemp;
    float    energyKWh;
};

// One record per calendar day-of-week (wday 0=Sun … 6=Sat)
struct DayRecord {
    char     date[12];      // "YYYY-MM-DD\0"
    uint32_t heatingSec;
    uint32_t energyWh;      // energyKWh × 1000
    uint16_t sessions;
} __attribute__((packed));

class Stats {
public:
    void beginNVS();
    void resetNVS();
    void update(bool relayOn, float waterTemp, float pzemEnergyKWh, bool pzemValid);

    uint32_t    getTodayHeatingSec()  const { return _todayHeatingSec; }
    uint8_t     getTodaySessions()    const { return _todaySessions;   }
    float       getTodayEnergyKWh()   const { return _todayEnergyKWh;  }
    float       getTodayCost()        const { return _todayEnergyKWh  * _pricePerKWh; }
    const char* getTodayDate()        const { return _todayDate;        }

    float    getMonthEnergyKWh()      const { return _monthEnergyKWh;  }
    float    getMonthCost()           const { return _monthEnergyKWh  * _pricePerKWh; }

    float    getYearEnergyKWh()       const { return _yearEnergyKWh;   }
    float    getYearCost()            const { return _yearEnergyKWh   * _pricePerKWh; }

    uint32_t getAllTimeHeatingSec()   const { return _allTimeHeatingSec; }
    uint32_t getAllTimeSessions()     const { return _allTimeSessions;   }
    float    getAllTimeEnergyKWh()    const { return _allTimeEnergyKWh;  }
    float    getAllTimeCost()         const { return _allTimeEnergyKWh  * _pricePerKWh; }

    void  setPricePerKWh(float price);
    float getPricePerKWh()            const { return _pricePerKWh; }

    uint8_t              getSessionCount()      const { return _sessionCount; }
    const HeatingSession& getSession(uint8_t idx) const;
    const DayRecord&      getDayRecord(uint8_t wday) const; // wday 0=Sun..6=Sat

    bool     isSessionActive()      const { return _wasOn; }
    uint32_t getActiveDurationSec() const;
    float    getActiveStartTemp()   const { return _sessionStartTemp; }

    String toJson() const;

private:
    static constexpr uint8_t MAX_SESSIONS = 20;

    HeatingSession _sessions[MAX_SESSIONS] = {};
    uint8_t  _head         = 0;
    uint8_t  _sessionCount = 0;

    bool     _wasOn              = false;
    uint32_t _sessionStartMs     = 0;
    time_t   _sessionStartEpoch  = 0;
    float    _sessionStartTemp   = NAN;
    float    _sessionStartEnergy = 0.0f;
    bool     _sessionEnergyValid = false;

    char     _todayDate[12]   = "";
    int      _todayYday       = -1;
    int      _todayYear       = -1;
    uint32_t _todayHeatingSec = 0;
    uint8_t  _todaySessions   = 0;
    float    _todayEnergyKWh  = 0.0f;

    float    _monthEnergyKWh  = 0.0f;
    int      _thisMonth       = -1;
    int      _thisMonthYear   = -1;

    float    _yearEnergyKWh   = 0.0f;
    int      _thisYear        = -1;

    uint32_t _allTimeHeatingSec = 0;
    uint32_t _allTimeSessions   = 0;
    float    _allTimeEnergyKWh  = 0.0f;

    float    _pricePerKWh     = 0.0f;

    bool     _nvsApplied      = false;
    int16_t  _nvsMoMonth      = -1;
    int16_t  _nvsMoYear       = -1;
    uint32_t _nvsMoWh         = 0;
    int16_t  _nvsYrYear       = -1;
    uint32_t _nvsYrWh         = 0;

    DayRecord _weekLog[7]     = {};
    int       _currentWday    = -1;

    void checkDayRollover(const struct tm& t);
    void sessionStarted(float waterTemp, float pzemEnergyKWh, bool pzemValid, time_t epoch);
    void sessionEnded  (float waterTemp, float pzemEnergyKWh, bool pzemValid);
    void pushSession(const HeatingSession& s);
    void saveToNVS() const;
};
