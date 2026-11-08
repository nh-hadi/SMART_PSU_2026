#include "ota_handler.h"

#if defined(ESP8266)
  #include <ESP8266WiFi.h>
  #include <ESP8266mDNS.h>
  #include <WiFiUdp.h>
#elif defined(ESP32)
  #include <WiFi.h>
  #include <ESPmDNS.h>
  #include <WiFiUdp.h>
#endif

#include <ArduinoOTA.h>
#include "output_ctrl.h"

static char currentIpStr[20] = "0.0.0.0";
static char currentApIpStr[20] = "192.168.4.1";
static char currentHostname[32] = OTA_DEFAULT_HOSTNAME;
static bool otaInitialized = false;
static unsigned long lastWifiReconnectAttempt = 0;
static const unsigned long WIFI_RECONNECT_INTERVAL_MS = 15000;

void ota_init(const char* ssid, const char* password, const char* ap_ssid, const char* ap_pass) {
  const char* targetSsid = (ssid && strlen(ssid) > 0) ? ssid : OTA_DEFAULT_SSID;
  const char* targetPass = (password) ? password : OTA_DEFAULT_PASSWORD;
  const char* targetApSsid = (ap_ssid && strlen(ap_ssid) > 0) ? ap_ssid : AP_DEFAULT_SSID;
  const char* targetApPass = (ap_pass) ? ap_pass : AP_DEFAULT_PASSWORD;

  strncpy(currentHostname, OTA_DEFAULT_HOSTNAME, sizeof(currentHostname) - 1);

  Serial.println("\n[WIFI & OTA] Menginisialisasi Mode Dual (AP + STA)...");
  Serial.printf("[OTA] Hostname Target: %s\n", currentHostname);

  // 1. Set WiFi Dual Mode: AP (Hotspot) + STA (Client ke Router)
  WiFi.mode(WIFI_AP_STA);

#if defined(ESP8266)
  WiFi.hostname(currentHostname);
  WiFi.setSleepMode(WIFI_NONE_SLEEP); // Matikan power-saving agar tidak drop & latency rendah
#elif defined(ESP32)
  WiFi.setHostname(currentHostname);
  WiFi.setSleep(false);               // Matikan power-saving modem agar koneksi tidak drop
#endif

  // 2. Aktifkan Access Point (Hotspot Mandiri ESP)
  bool apSuccess = WiFi.softAP(targetApSsid, targetApPass);
  if (apSuccess) {
    snprintf(currentApIpStr, sizeof(currentApIpStr), "%s", WiFi.softAPIP().toString().c_str());
    Serial.println("==================================================");
    Serial.printf("[AP MODE] HOTSPOT AKTIF!\n");
    Serial.printf("  SSID     : %s\n", targetApSsid);
    Serial.printf("  Password : %s\n", targetApPass);
    Serial.printf("  IP ESP   : %s (Gunakan IP ini di Flutter!)\n", currentApIpStr);
    Serial.println("==================================================");
  } else {
    Serial.println("[AP MODE] Gagal mengaktifkan Access Point!");
  }

  // 3. Hubungkan ke Router Station jika SSID bukan default placeholder
  if (strcmp(targetSsid, "YOUR_WIFI_SSID") == 0) {
    Serial.println("[STA] SSID router masih bernilai default ('YOUR_WIFI_SSID'). Melewati koneksi STA.");
    return;
  }

  Serial.printf("[STA] Mencoba menghubungkan ke Router WiFi: %s", targetSsid);
  WiFi.begin(targetSsid, targetPass);

  // Tunggu koneksi secara wajar (maksimum 6 detik)
  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 6000) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    snprintf(currentIpStr, sizeof(currentIpStr), "%s", WiFi.localIP().toString().c_str());
    Serial.printf("[STA] [SUKSES] Terhubung ke Router WiFi!\n");
    Serial.printf("[STA] Router IP Address : %s\n", currentIpStr);
    Serial.printf("[STA] Signal RSSI       : %d dBm\n", WiFi.RSSI());

    // Konfigurasi ArduinoOTA
    ArduinoOTA.setHostname(currentHostname);

    if (strlen(OTA_AUTH_PASSWORD) > 0) {
      ArduinoOTA.setPassword(OTA_AUTH_PASSWORD);
      Serial.println("[OTA] Proteksi Password: AKTIF");
    }

    ArduinoOTA.onStart([]() {
      String type = (ArduinoOTA.getCommand() == U_FLASH) ? "sketch (Firmware)" : "filesystem (SPIFFS/LittleFS)";
      Serial.printf("\n[OTA] >>> PROSES UPDATE DIMULAI: %s <<<\n", type.c_str());
      output_set_all(false);
      Serial.println("[OTA] [SAFETY] Semua output dimatikan selama flashing.");
    });

    ArduinoOTA.onEnd([]() {
      Serial.println("\n[OTA] >>> UPDATE SELESAI! Restarting... <<<\n");
    });

    ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
      unsigned int percent = (progress / (total / 100));
      Serial.printf("[OTA Progress] %u%% (%u / %u bytes)\r", percent, progress, total);
    });

    ArduinoOTA.onError([](ota_error_t error) {
      Serial.printf("\n[OTA ERROR] Kode [%u]\n", error);
    });

    ArduinoOTA.begin();
    otaInitialized = true;
    Serial.printf("[OTA] Service ArduinoOTA Siap! Akses via: %s.local\n", currentHostname);
  } else {
    Serial.println("[STA] [INFO] Belum terhubung ke Router WiFi. Namun ESP tetap bisa diakses via Access Point (Hotspot).");
  }
}

void ota_handle(void) {
  if (WiFi.status() == WL_CONNECTED) {
    if (!otaInitialized) {
      ArduinoOTA.setHostname(currentHostname);
      ArduinoOTA.begin();
      otaInitialized = true;
      snprintf(currentIpStr, sizeof(currentIpStr), "%s", WiFi.localIP().toString().c_str());
      Serial.printf("\n[STA] Terhubung kembali ke Router! IP: %s\n", currentIpStr);
    }
    ArduinoOTA.handle();
  } else {
    otaInitialized = false;
    unsigned long now = millis();
    if (now - lastWifiReconnectAttempt >= WIFI_RECONNECT_INTERVAL_MS) {
      lastWifiReconnectAttempt = now;
      if (strcmp(OTA_DEFAULT_SSID, "YOUR_WIFI_SSID") != 0) {
        WiFi.reconnect();
      }
    }
  }
}

bool ota_is_wifi_connected(void) {
  return (WiFi.status() == WL_CONNECTED || WiFi.softAPgetStationNum() > 0);
}

const char* ota_get_ip(void) {
  if (WiFi.status() == WL_CONNECTED) {
    snprintf(currentIpStr, sizeof(currentIpStr), "%s", WiFi.localIP().toString().c_str());
    return currentIpStr;
  }
  return currentApIpStr;
}

const char* ota_get_hostname(void) {
  return currentHostname;
}

int8_t ota_get_rssi(void) {
  if (WiFi.status() == WL_CONNECTED) {
    return WiFi.RSSI();
  }
  return 0;
}

void ota_print_info(void) {
  Serial.println("\n=== STATUS JARINGAN & OTA ===");
  Serial.printf(" Hostname       : %s.local\n", currentHostname);
  Serial.printf(" AP (Hotspot)   : SSID: %s | IP: %s | Klien: %d\n", AP_DEFAULT_SSID, currentApIpStr, WiFi.softAPgetStationNum());
  Serial.printf(" STA (Router)   : Status: %s", (WiFi.status() == WL_CONNECTED) ? "CONNECTED" : "DISCONNECTED");
  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf(" | IP: %s | SSID: %s | Signal: %d dBm\n", ota_get_ip(), WiFi.SSID().c_str(), ota_get_rssi());
  } else {
    Serial.println();
  }
  Serial.println("=============================\n");
}

