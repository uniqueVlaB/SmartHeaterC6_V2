#pragma once
#include <Arduino.h>

enum class FaultCode : uint8_t {
    None = 0,
    DisplayInitFailed,
    WiFiConnectFailed,
    TempSensorLost,
    OverTemperature,
    BodyOverTemperature,
    RelayStuckOn,
    BodySensorLost,
    HeaterElementFault,
    OverCurrent,
    InternalError,
};

class FaultManager {
public:
    static void raise(FaultCode code, const String& details = "");

    static bool        isFaulted()  { return _code != FaultCode::None; }
    static FaultCode   getCode()    { return _code;    }
    static const char* getCodeStr() { return codeToStr(_code); }
    static const String& getDetails() { return _details; }

    static const char* codeToStr(FaultCode c);

    // Reset all fault-detection timers (call after setup completes)
    static void resetTimers();

    // Centralized fault checks – call from loop()
    static void checkWaterTemp(float waterTemp, uint32_t now);
    static void checkBodyTemp(float bodyTemp, uint32_t now);
    static void checkPower(const struct PowerData& p, bool relayOn, uint32_t now);

    // RTC memory: track whether previous boot ended in a fault
    static void saveRebootReason(bool wasFault);
    static bool previousBootFaulted();

private:
    static FaultCode _code;
    static String    _details;

    // Water temp fault tracking
    static uint32_t _tempNanSince;
    static bool     _tempWasValid;

    // Body temp fault tracking
    static uint32_t _bodyNanSince;
    static bool     _bodyWasValid;
    static bool     _bodyEverDetected;

    // Relay stuck / element fault tracking
    static uint32_t _relayOffSince;
    static bool     _relayWasOn;
    static uint32_t _relayOnSince;
    static bool     _relayWasOnElem;
};
