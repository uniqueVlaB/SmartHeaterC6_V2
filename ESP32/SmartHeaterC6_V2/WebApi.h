#pragma once
#include <WebServer.h>
#include "HeaterController.h"
#include "TempSensors.h"
#include "PowerMeter.h"
#include "HeaterRelay.h"
#include "Scheduler.h"
#include "TimeSync.h"
#include "Stats.h"
#include "StatusLed.h"
#include "Tariff.h"

class WebApi {
public:
    WebApi(HeaterController& ctrl, TempSensors& temp,
           PowerMeter& pzem, HeaterRelay& relay,
           Scheduler& scheduler, TimeSync& timeSync,
           Stats& stats, StatusLed& led, Tariff& tariff, uint16_t port = 80);
    void begin();
    void handle();   // call in loop
    bool shouldRestart() const { return _shouldRestart; }
    WebServer& server() { return _server; }

private:
    WebServer         _server;
    HeaterController& _ctrl;
    TempSensors&      _temp;
    PowerMeter&       _pzem;
    HeaterRelay&      _relay;
    Scheduler&        _scheduler;
    TimeSync&         _timeSync;
    Stats&            _stats;
    StatusLed&        _led;
    Tariff&           _tariff;

    bool     _shouldRestart  = false;
    uint32_t _restartStartMs = 0;

    // ── Periodic restart ───────────────────────────────
    bool     _periodicRestartEnabled = false;
    uint16_t _periodicRestartIntervalH = 24;
    uint32_t _lastPeriodicCheck = 0;

    void loadPeriodicRestartNVS();
    void savePeriodicRestartNVS();
    void checkPeriodicRestart();

    // ── Heater handlers ────────────────────────────────
    void handleStatus();
    void handleHeaterOn();
    void handleHeaterOff();
    void handleDefaultModeOn();
    void handleDefaultModeOff();
    void handleHeaterPause();
    void handleHeaterBoost();
    void handleSetTarget();
    void handleSetMaxTarget();
    void handleSetHysteresis();
    void handleGetHysteresis();
    void handlePower();
    void handleResetEnergy();
    void handleNotFound();

    // ── Duty-cycle handlers ────────────────────────────
    void handleCycleGet();
    void handleCycleOn();
    void handleCycleOff();
    void handleCycleConfig();

    // ── Schedule handlers ──────────────────────────────
    void handleScheduleGet();
    void handleScheduleAdd();
    void handleScheduleEdit();
    void handleScheduleRemove();
    void handleScheduleEnable();
    void handleScheduleDisable();
    void handleScheduleClear();

    // ── LED handlers ───────────────────────────────────
    void handleLedGet();
    void handleLedOn();
    void handleLedOff();

    // ── System handlers ────────────────────────────────
    void handleFactoryReset();
    void handleRestart();
    void handlePeriodicRestartGet();
    void handlePeriodicRestartOn();
    void handlePeriodicRestartOff();
    void handlePeriodicRestartConfig();

    // ── Time handler ──────────────────────────────────
    void handleTime();
    // ── Fault handler ────────────────────────────
    void handleFault();
    // ── Stats handlers ───────────────────────────
    void handleStats();
    void handleSetPrice();
    void handleStatsReset();
    // ── Tariff handlers ──────────────────────────
    void handleTariffGet();
    void handleTariffOn();
    void handleTariffOff();
    void handleTariffConfig();

    // ── Helpers ───────────────────────────────────────
    void sendJson(int code, const String& json);
    static uint16_t parseHHMM(const String& s);
    static float getCpuLoadPercent();
};
