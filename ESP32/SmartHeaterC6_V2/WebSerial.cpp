#include "WebSerial.h"
#include <Arduino.h>

WebSerial webSerial;

size_t WebSerial::write(uint8_t c) {
    Serial.write(c);
    _buf[_head % WEBSERIAL_BUF_SIZE] = c;
    _head++;
    _totalWritten++;
    return 1;
}

size_t WebSerial::write(const uint8_t* buf, size_t len) {
    Serial.write(buf, len);
    for (size_t i = 0; i < len; i++) {
        _buf[_head % WEBSERIAL_BUF_SIZE] = buf[i];
        _head++;
    }
    _totalWritten += len;
    return len;
}

void WebSerial::begin(WebServer& server) {
    server.on("/console",     HTTP_GET, [this, &server]() { handleConsolePage(server); });
    server.on("/console/log", HTTP_GET, [this, &server]() { handleConsoleLog(server);  });
    webSerial.println("[WebSerial] Console at /console");
}

void WebSerial::handleConsolePage(WebServer& server) {
    static const char PAGE[] PROGMEM = R"rawliteral(<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>SmartHeater Console</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#1e1e1e;color:#d4d4d4;font-family:Consolas,'Courier New',monospace;font-size:14px}
#bar{position:fixed;top:0;left:0;right:0;height:36px;background:#333;display:flex;align-items:center;padding:0 12px;z-index:1}
#bar span{color:#569cd6;font-weight:bold;flex:1}
#bar button{background:#444;color:#ccc;border:1px solid #666;border-radius:4px;padding:4px 12px;cursor:pointer;margin-left:8px}
#bar button:hover{background:#555}
#log{white-space:pre-wrap;word-break:break-all;padding:44px 12px 12px;min-height:100vh}
</style></head><body>
<div id="bar"><span>SmartHeater Serial Console</span>
<label style="color:#aaa;font-size:12px"><input type="checkbox" id="auto" checked> Auto-scroll</label>
<button onclick="clearLog()">Clear</button>
<button onclick="pauseToggle()" id="pbtn">Pause</button></div>
<div id="log"></div>
<script>
var pos=0,paused=false,el=document.getElementById('log');
function poll(){
 if(paused)return;
 fetch('/console/log?pos='+pos).then(r=>{
  if(!r.ok)return;
  var np=r.headers.get('X-Pos');
  if(np)pos=parseInt(np);
  return r.text();
 }).then(t=>{
  if(t&&t.length){el.textContent+=t;
   if(document.getElementById('auto').checked)window.scrollTo(0,document.body.scrollHeight);}
 });
}
setInterval(poll,500);
function clearLog(){el.textContent=''}
function pauseToggle(){paused=!paused;document.getElementById('pbtn').textContent=paused?'Resume':'Pause';}
</script></body></html>)rawliteral";
    server.send(200, "text/html", PAGE);
}

void WebSerial::handleConsoleLog(WebServer& server) {
    uint32_t clientPos = 0;
    if (server.hasArg("pos"))
        clientPos = strtoul(server.arg("pos").c_str(), nullptr, 10);

    uint32_t total = _totalWritten;

    if (clientPos > total)
        clientPos = 0;

    uint32_t available = total - clientPos;
    if (available > WEBSERIAL_BUF_SIZE)
        clientPos = total - WEBSERIAL_BUF_SIZE;

    uint32_t toSend = total - clientPos;

    String out;
    out.reserve(toSend);
    for (uint32_t i = clientPos; i < total; i++)
        out += (char)_buf[i % WEBSERIAL_BUF_SIZE];

    server.sendHeader("X-Pos", String(total));
    server.sendHeader("Cache-Control", "no-cache");
    server.send(200, "text/plain", out);
}
