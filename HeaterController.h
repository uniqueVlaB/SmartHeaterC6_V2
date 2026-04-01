#pragma once
#include "HeaterRelay.h"
#include "TempSensors.h"
#include "Config.h"
#include "Scheduler.h"
#include "TimeSync.h"

enum class HeaterReason : uint8_t {
    Default,
    Schedule,
    Boost,
    Paused,
    CyclePause,
    Waiting,
    Disabled,
};
const char* heaterReasonStr(HeaterReason r);

class HeaterController {
public:
    HeaterController(HeaterRelay& relay, TempSensors& sensors);

    void  update();
    void  enable();
    void  disable();
    void  emergencyOff();                   // relay off without NVS write (OTA safe)
    void  disableFor(uint32_t minutes);
    uint32_t pauseRemaining() const;
    void  boostTo(float tempC);
    float getBoostTarget() const;
    bool  isEnabled() const;
    void  setDefaultMode(bool enabled);
    bool  isDefaultModeEnabled() const;

    // ── Duty-cycle mode ──────────────────────────────────
    void  setCycleMode(bool enabled);
    bool  isCycleModeEnabled() const;
    void  setCycleOnMinutes(uint16_t min);
    void  setCycleOffMinutes(uint16_t min);
    uint16_t getCycleOnMinutes()  const;
    uint16_t getCycleOffMinutes() const;
    uint32_t getCyclePauseRemaining() const;

    void  setTarget(float tempC);
    float getTarget() const;
    float getEffectiveTarget() const { return _effectiveTarget; }

    void  setMaxTarget(float tempC);
    float getMaxTarget() const;

    void  setHysteresis(float deg);
    float getHysteresis() const;

    HeaterReason getReason() const { return _reason; }
    const ScheduleSlot* getActiveSlot() const { return _activeSlot; }

    void setScheduler(Scheduler* sched, TimeSync* ts);
    bool isScheduleActive() const { return _scheduleActive; }

    void beginNVS();
    void flushNVS();                        // call periodically; writes only if dirty & throttle elapsed
    void resetNVS();

private:
    HeaterRelay& _relay;
    TempSensors& _sensors;
    float        _target          = HEATER_DEFAULT_TARGET;
    float        _effectiveTarget = HEATER_DEFAULT_TARGET;
    float        _maxTarget       = HEATER_MAX_USER_TARGET;
    float        _hysteresis      = HEATER_HYSTERESIS;
    bool         _enabled              = false;
    bool         _defaultModeEnabled    = true;
    bool         _scheduleActive        = false;
    uint32_t     _pauseUntil      = 0;
    float        _boostTarget     = 0;
    HeaterReason _reason          = HeaterReason::Disabled;
    const ScheduleSlot* _activeSlot = nullptr;

    // Duty-cycle state
    bool     _cycleEnabled    = false;
    uint16_t _cycleOnMin      = 10;
    uint16_t _cycleOffMin     = 5;
    bool     _cycleInPause    = false;
    uint32_t _cyclePhaseStart = 0;
    bool     _cycleStarted    = false;

    Scheduler*   _scheduler = nullptr;
    TimeSync*    _timeSync  = nullptr;

    // NVS write throttle
    bool     _nvsDirty     = false;
    uint32_t _lastNvsWrite = 0;

    void saveToNVS() const;
    void markDirty();
};
