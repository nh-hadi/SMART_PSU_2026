#include "udp_handler.h"
#include "output_ctrl.h"

#if defined(ESP8266)
  #include <ESP8266WiFi.h>
  #include <ESP8266WebServer.h>
  #include <ESP8266HTTPUpdateServer.h>
  static ESP8266WebServer httpServer(80);
  static ESP8266HTTPUpdateServer httpUpdater;
#elif defined(ESP32)
  #include <WiFi.h>
  #include <WebServer.h>
  #include <Update.h>
  static WebServer httpServer(80);
#endif

#include <WiFiUdp.h>
#include "ina3221.h"

static WiFiUDP udp;
static uint16_t localUdpPort = UDP_DEFAULT_PORT;
static bool udpStarted = false;
static char jsonBuffer[384];

// Cache data sensor terakhir untuk REST API & Telemetri
static float lastV1 = 0, lastI1 = 0;
static float lastV2 = 0, lastI2 = 0;
static float lastV3 = 0, lastI3 = 0;
static float lastDm = 0, lastDp = 0, lastAvo = 0;
static unsigned long lastI2cScanTime = 0;
static char cachedI2cAddrs[48] = "SCANNING";

static void setCorsHeaders() {
  httpServer.sendHeader("Access-Control-Allow-Origin", "*");
  httpServer.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  httpServer.sendHeader("Access-Control-Allow-Headers", "*");
  httpServer.sendHeader("Access-Control-Allow-Private-Network", "true");
  httpServer.sendHeader("Connection", "close");
}

void udp_telemetry_init(uint16_t port) {
  localUdpPort = port;
  
  // Mulai UDP socket
  udp.begin(localUdpPort);
  udpStarted = true;
  Serial.printf("[UDP] Telemetry Port: %d (Active)\n", localUdpPort);

  // 1. Endpoint /data untuk Flutter Web Browser & App
  httpServer.on("/data", HTTP_GET, []() {
    setCorsHeaders();
    snprintf(jsonBuffer, sizeof(jsonBuffer),
      "{\"v1\":%.2f,\"i1\":%.1f,"
      "\"v2\":%.2f,\"i2\":%.1f,"
      "\"v3\":%.2f,\"i3\":%.1f,"
      "\"dm\":%.2f,\"dp\":%.2f,\"avo\":%.2f,"
      "\"m\":%d,\"r1\":%d,\"r2\":%d,"
      "\"i2c\":\"%s\"}",
      lastV1, lastI1,
      lastV2, lastI2,
      lastV3, lastI3,
      lastDm, lastDp, lastAvo,
      output_get_mosfet() ? 1 : 0,
      output_get_relay1() ? 1 : 0,
      output_get_relay2() ? 1 : 0,
      cachedI2cAddrs
    );
    httpServer.send(200, "application/json", jsonBuffer);
  });

  // 2. Endpoint /cmd untuk Kontrol Switch dari Flutter Web Browser
  httpServer.on("/cmd", HTTP_GET, []() {
    setCorsHeaders();
    if (httpServer.hasArg("set")) {
      String target = httpServer.arg("set");
      int val = httpServer.hasArg("val") ? httpServer.arg("val").toInt() : 1;
      bool state = (val == 1);

      if (target == "mosfet") output_set_mosfet(state);
      else if (target == "relay1") output_set_relay1(state);
      else if (target == "relay2") output_set_relay2(state);
      else if (target == "all") output_set_all(state);
    }
    httpServer.send(200, "application/json", "{\"status\":\"ok\"}");
  });

  // 3. Endpoint /ping untuk Uji Koneksi & Latency
  httpServer.on("/ping", HTTP_GET, []() {
    setCorsHeaders();
    snprintf(jsonBuffer, sizeof(jsonBuffer),
      "{\"status\":\"pong\",\"device\":\"smartpsu\",\"uptime_ms\":%lu,\"rssi\":%d}",
      millis(),
      (WiFi.status() == WL_CONNECTED) ? WiFi.RSSI() : 0
    );
    httpServer.send(200, "application/json", jsonBuffer);
  });

  // 4. Endpoint /test untuk Kirim & Terima Custom Pesan (Diagnostics)
  httpServer.on("/test", HTTP_GET, []() {
    setCorsHeaders();
    String echoMsg = httpServer.hasArg("msg") ? httpServer.arg("msg") : "TEST_OK";
    snprintf(jsonBuffer, sizeof(jsonBuffer),
      "{\"status\":\"ok\",\"echo\":\"%s\",\"uptime_ms\":%lu,\"rssi\":%d}",
      echoMsg.c_str(),
      millis(),
      (WiFi.status() == WL_CONNECTED) ? WiFi.RSSI() : 0
    );
    httpServer.send(200, "application/json", jsonBuffer);
  });

  // Handle OPTIONS CORS preflight
  httpServer.onNotFound([]() {
    if (httpServer.method() == HTTP_OPTIONS) {
      setCorsHeaders();
      httpServer.send(204);
    } else {
      httpServer.send(404, "text/plain", "Not Found");
    }
  });

  // 5. HTTP OTA Update Server
  #if defined(ESP8266)
    httpUpdater.setup(&httpServer, "/update");
  #elif defined(ESP32)
    httpServer.on("/update", HTTP_POST, []() {
      setCorsHeaders();
      httpServer.send(200, "text/plain", (Update.hasError()) ? "UPDATE_FAIL" : "UPDATE_OK");
      ESP.restart();
    }, []() {
      HTTPUpload& upload = httpServer.upload();
      if (upload.status == UPLOAD_FILE_START) {
        Serial.printf("[HTTP OTA] Mulai: %s\n", upload.filename.c_str());
        output_set_all(false);
        if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
          Update.printError(Serial);
        }
      } else if (upload.status == UPLOAD_FILE_WRITE) {
        if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
          Update.printError(Serial);
        }
      } else if (upload.status == UPLOAD_FILE_END) {
        if (Update.end(true)) {
          Serial.printf("[HTTP OTA] Sukses: %u bytes\n", upload.totalSize);
        }
      }
    });
  #endif

  httpServer.begin();
  Serial.println("[HTTP SERVER] Aktif dan siap melayani REST API & Web Dashboard di Port 80");
}

void udp_telemetry_handle(void) {
  httpServer.handleClient();

  // Tangani paket UDP masuk (perintah kontrol dari HP Flutter)
  if (udpStarted) {
    int packetSize = udp.parsePacket();
    if (packetSize > 0) {
      char rxBuf[128];
      int len = udp.read(rxBuf, sizeof(rxBuf) - 1);
      if (len > 0) {
        rxBuf[len] = '\0';
        String msg = String(rxBuf);
        msg.trim();

        // Format cepat: "m1", "m0", "r11", "r10", "r21", "r20", "all1", "all0"
        // atau JSON: {"cmd":"mosfet","val":1}
        if (msg == "m1" || msg.indexOf("\"cmd\":\"mosfet\",\"val\":1") >= 0) {
          output_set_mosfet(true);
        } else if (msg == "m0" || msg.indexOf("\"cmd\":\"mosfet\",\"val\":0") >= 0) {
          output_set_mosfet(false);
        } else if (msg == "r11" || msg.indexOf("\"cmd\":\"relay1\",\"val\":1") >= 0) {
          output_set_relay1(true);
        } else if (msg == "r10" || msg.indexOf("\"cmd\":\"relay1\",\"val\":0") >= 0) {
          output_set_relay1(false);
        } else if (msg == "r21" || msg.indexOf("\"cmd\":\"relay2\",\"val\":1") >= 0) {
          output_set_relay2(true);
        } else if (msg == "r20" || msg.indexOf("\"cmd\":\"relay2\",\"val\":0") >= 0) {
          output_set_relay2(false);
        } else if (msg == "all1" || msg.indexOf("\"cmd\":\"all\",\"val\":1") >= 0) {
          output_set_all(true);
        } else if (msg == "all0" || msg.indexOf("\"cmd\":\"all\",\"val\":0") >= 0) {
          output_set_all(false);
        }

        // Kirim konfirmasi balik ke pengirim
        IPAddress remoteIp = udp.remoteIP();
        uint16_t remotePort = udp.remotePort();
        udp.beginPacket(remoteIp, remotePort);
        snprintf(jsonBuffer, sizeof(jsonBuffer), "{\"ack\":\"ok\",\"m\":%d,\"r1\":%d,\"r2\":%d}",
                 output_get_mosfet() ? 1 : 0, output_get_relay1() ? 1 : 0, output_get_relay2() ? 1 : 0);
        udp.write((const uint8_t*)jsonBuffer, strlen(jsonBuffer));
        udp.endPacket();
      }
    }
  }
}

void udp_broadcast_telemetry(const ina3221_data_t* ina, const ads1115_data_t* ads) {
  if (!ina || !ads) return;

  // Format status alamat I2C yang aktif tanpa memblokir CPU ESP8266
  snprintf(cachedI2cAddrs, sizeof(cachedI2cAddrs), "INA:0x%02X, ADS:0x%02X", 
           ina3221_get_address(), ads1115_get_address());

  // Simpan ke cache untuk disajikan ke HTTP REST API
  lastV1 = ina->ch1.busVoltage_V; lastI1 = ina->ch1.current_mA;
  lastV2 = ina->ch2.busVoltage_V; lastI2 = ina->ch2.current_mA;
  lastV3 = ina->ch3.busVoltage_V; lastI3 = ina->ch3.current_mA;
  lastDm = ads->a1.vin; lastDp = ads->a2.vin; lastAvo = ads->a3.vin;

  if (udpStarted) {
    snprintf(jsonBuffer, sizeof(jsonBuffer),
      "{\"type\":\"telemetry\","
      "\"v1\":%.2f,\"i1\":%.1f,"
      "\"v2\":%.2f,\"i2\":%.1f,"
      "\"v3\":%.2f,\"i3\":%.1f,"
      "\"dm\":%.2f,\"dp\":%.2f,\"avo\":%.2f,"
      "\"m\":%d,\"r1\":%d,\"r2\":%d,"
      "\"i2c\":\"%s\"}",
      lastV1, lastI1, lastV2, lastI2, lastV3, lastI3,
      lastDm, lastDp, lastAvo,
      output_get_mosfet() ? 1 : 0,
      output_get_relay1() ? 1 : 0,
      output_get_relay2() ? 1 : 0,
      cachedI2cAddrs
    );

    IPAddress broadcastIp(255, 255, 255, 255);
    udp.beginPacket(broadcastIp, localUdpPort);
    udp.write((const uint8_t*)jsonBuffer, strlen(jsonBuffer));
    udp.endPacket();
  }
}

