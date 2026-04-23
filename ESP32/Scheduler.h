#pragma once
#include <Arduino.h>
#include <time.h>

#define SCHEDULER_MAX_SLOTS 8

#define DAY_MON (1 << 0)
#define DAY_TUE (1 << 1)
#define DAY_WED (1 << 2)
#define DAY_THU (1 << 3)
#define DAY_FRI (1 << 4)
#define DAY_SAT (1 << 5)
#define DAY_SUN (1 << 6)
#define DAY_WORKDAYS (DAY_MON | DAY_TUE | DAY_WED | DAY_THU | DAY_FRI)
#define DAY_WEEKEND  (DAY_SAT | DAY_SUN)
#define DAY_ALL      (0x7F)

struct ScheduleSlot {
    uint8_t  id;
    uint8_t  dayMask;
    uint16_t fromMin;
    uint16_t toMin;
    float    target;
    uint8_t  enabled;
    uint8_t  _pad[2];
};

class Scheduler {
public:
    void begin();

    bool isActive(const struct tm& t, float& outTarget) const;
    bool isActive(const struct tm& t, float& outTarget, const ScheduleSlot*& outSlot) const;

    bool addSlot(uint8_t dayMask, uint16_t fromMin, uint16_t toMin,
                 float target = 0.0f, bool enabled = true);

    bool removeSlot(uint8_t id);
    bool setEnabled(uint8_t id, bool enabled);
    bool editSlot(uint8_t id, int dayMask, int fromMin, int toMin, float target);

    const ScheduleSlot* getSlots() const { return _slots; }
    uint8_t             getCount()  const { return _count;  }

    String toJson() const;
    void clear();
    void resetNVS();

    static uint8_t tmDayBit(int tm_wday);

private:
    ScheduleSlot _slots[SCHEDULER_MAX_SLOTS] = {};
    uint8_t      _count  = 0;
    uint8_t      _nextId = 1;

    void loadFromNVS();
    void saveToNVS() const;
    void loadDefaults();
};
