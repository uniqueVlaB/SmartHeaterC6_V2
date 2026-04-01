#pragma once
#include <Print.h>
#include <WebServer.h>

#define WEBSERIAL_BUF_SIZE  8192

class WebSerial : public Print {
public:
    void begin(WebServer& server);

    size_t write(uint8_t c) override;
    size_t write(const uint8_t* buf, size_t len) override;

    uint32_t totalWritten() const { return _totalWritten; }

private:
    void handleConsolePage(WebServer& server);
    void handleConsoleLog(WebServer& server);

    uint8_t  _buf[WEBSERIAL_BUF_SIZE] = {};
    uint32_t _head         = 0;
    uint32_t _totalWritten = 0;
};

extern WebSerial webSerial;
