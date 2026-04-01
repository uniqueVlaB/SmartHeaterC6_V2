# SmartHeater V2

An ESP32-C6-based smart water heater controller with temperature regulation, power monitoring, scheduling, and full HTTP API for Home Assistant integration.

## Problem It Solves

Most residential water heaters use a simple thermostat with no remote control, no scheduling, and no power monitoring. If a sensor fails or the relay sticks, nothing prevents the water from over-heating.

SmartHeater V2 adds:
- **Precise thermostat** with configurable target, hysteresis, and hard safety cap  
- **Scheduled heating** — up to 16 time-based slots with per-slot target temperatures  
- **Full power monitoring** — voltage, current, power, energy, frequency, power factor (PZEM-004T)  
- **Multi-layer fault protection** — over-temperature, sensor loss, relay stuck-on, element fault, over-current  
- **REST API** — every setting readable and changeable over HTTP for Home Assistant or any automation platform  
- **OLED display + status LED + physical button**  
- **OTA firmware updates** over Wi-Fi  
- **Duty-cycle mode** — periodic relay cool-down for SSR thermal management  
- **Energy statistics with cost tracking** persisted in NVS  

## Hardware

| Component | Model | Connection |
|---|---|---|
| MCU | MakerGO ESP32-C6 SuperMini | — |
| Relay | SSR module | GPIO 20 |
| Water temp sensor | DS18B20 (waterproof) | GPIO 19 (OneWire) |
| Body temp sensor | DS18B20 | GPIO 19 (same bus) |
| Power meter | PZEM-004T v3.0 | TX→GPIO 0, RX→GPIO 1 |
| Display | SH1107 128×64 OLED (I²C) | SDA→GPIO 15, SCL→GPIO 14 |
| Status LED | WS2812B (on-board) | GPIO 8 |
| Button | Momentary push-button | GPIO 2 (INPUT_PULLUP) |

## Configuration

All compile-time settings are in `Config.h`:

| Setting | Default | Description |
|---|---|---|
| `HEATER_DEFAULT_TARGET` | 55 °C | Default thermostat target |
| `HEATER_DEFAULT_MAX_TARGET` | 82 °C | Maximum allowed target (auto-capped to fault temp − 3 °C) |
| `HEATER_FAULT_TEMP` | 85 °C | Water over-temperature fault threshold |
| `BODY_FAULT_TEMP` | 90 °C | Body over-temperature fault threshold |
| `HEATER_DEFAULT_HYSTERESIS` | 3 °C | Thermostat hysteresis |
| `RELAY_MIN_SWITCH_MS` | 5000 ms | Anti-chatter: minimum time between relay state changes |
| `NVS_WRITE_THROTTLE_MS` | 30000 ms | Minimum interval between NVS writes (flash wear reduction) |
| `WDT_TIMEOUT_SEC` | 30 s | Hardware watchdog timeout |

### WiFi Credentials

Create a `secrets.h` file (git-ignored):

```cpp
#pragma once
#define SECRET_WIFI_SSID     "YourNetworkName"
#define SECRET_WIFI_PASSWORD "YourPassword"
```

## Building

Open `SmartHeaterC6_V2.ino` in Arduino IDE.

**Board:** ESP32C6 Dev Module  
**Flash Size:** 4 MB  
**Partition Scheme:** Default 4MB with spiffs  

Required libraries:
- FastLED
- Adafruit SH110X
- Adafruit GFX
- PZEM004Tv30
- OneWire
- DallasTemperature

## REST API

All endpoints return JSON. Base URL: `http://<device-ip>`

### Status & Control

| Method | Endpoint | Description |
|---|---|---|
| GET | `/status` | Full system status (temps, power, state, schedule, faults, CPU) |
| POST | `/heater/on` | Enable heater |
| POST | `/heater/off` | Disable heater |
| POST | `/heater/target?temp=N` | Set target temperature |
| POST | `/heater/maxTarget?temp=N` | Set maximum target (capped at fault − 3 °C) |
| POST | `/heater/hysteresis?value=N` | Set hysteresis (0.5–15 °C) |
| GET | `/heater/hysteresis` | Get current hysteresis |
| POST | `/heater/pause?minutes=N` | Pause heating (1–1440 min) |
| POST | `/heater/boost?temp=N` | One-shot boost to target |
| POST | `/heater/default/on` | Enable default mode |
| POST | `/heater/default/off` | Disable default mode |

### Duty-Cycle (SSR Cool-Down)

| Method | Endpoint | Description |
|---|---|---|
| GET | `/heater/cycle` | Get cycle mode status |
| POST | `/heater/cycle/on` | Enable duty-cycle mode |
| POST | `/heater/cycle/off` | Disable duty-cycle mode |
| POST | `/heater/cycle/config?on=N&off=M` | Set on/off minutes (1–120 each) |

### Power Monitoring

| Method | Endpoint | Description |
|---|---|---|
| GET | `/power` | Current power readings |
| POST | `/power/reset` | Reset energy counter |

### Schedule

| Method | Endpoint | Description |
|---|---|---|
| GET | `/schedule` | List all slots |
| POST | `/schedule/add?days=N&from=HH:MM&to=HH:MM&target=T` | Add slot (days = bitmask Mon=1…Sun=64) |
| POST | `/schedule/edit?id=N&days=D&from=HH:MM&to=HH:MM&target=T` | Edit slot (omit fields to keep existing) |
| POST | `/schedule/remove?id=N` | Remove slot |
| POST | `/schedule/enable?id=N` | Enable slot |
| POST | `/schedule/disable?id=N` | Disable slot |
| POST | `/schedule/clear` | Remove all slots |

### LED Control

| Method | Endpoint | Description |
|---|---|---|
| GET | `/led` | Get LED enabled state |
| POST | `/led/on` | Enable LED |
| POST | `/led/off` | Disable LED |

### System

| Method | Endpoint | Description |
|---|---|---|
| POST | `/system/restart` | Restart device |
| POST | `/system/factory-reset` | Reset all NVS settings and restart |
| GET | `/system/periodic-restart` | Get periodic restart config |
| POST | `/system/periodic-restart/on` | Enable periodic restart |
| POST | `/system/periodic-restart/off` | Disable periodic restart |
| POST | `/system/periodic-restart/config?hours=N` | Set interval (1–168 h) |

### Other

| Method | Endpoint | Description |
|---|---|---|
| GET | `/time` | Current time and sync status |
| GET | `/fault` | Fault status, code, details |
| GET | `/stats` | Energy statistics and cost |
| POST | `/stats/price?value=N` | Set price per kWh |
| POST | `/stats/reset` | Reset statistics |
| GET | `/console` | Web serial console (browser) |

## Fault Protection

The system monitors for these fault conditions and enters a safe fault loop (relay OFF, LED blinks red, OTA + API stay active):

| Code | Condition | Threshold |
|---|---|---|
| `OverTemperature` | Water temp ≥ fault limit | 85 °C |
| `BodyOverTemperature` | Body temp ≥ fault limit | 90 °C |
| `TempSensorLost` | Water sensor returns NaN | > 60 s |
| `BodySensorLost` | Body sensor returns NaN (after detection) | > 120 s |
| `RelayStuckOn` | Power detected with relay OFF | > 10 s, ≥ 20 W |
| `HeaterElementFault` | No power with relay ON | > 30 s, < 50 W |
| `OverCurrent` | Power exceeds rated max | > 2500 W |


## License

MIT
