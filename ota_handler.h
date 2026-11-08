#ifndef OTA_HANDLER_H
#define OTA_HANDLER_H

#include <Arduino.h>

// =======================================================
// KONFIGURASI DEFAULT OTA & WIFI
// =======================================================
#define OTA_DEFAULT_HOSTNAME    "smartpsu"

// Mode Station (Connect ke Router Rumah/Lab)
#define OTA_DEFAULT_SSID        "SMARTCAMPUS"
#define OTA_DEFAULT_PASSWORD    "12345678"

// Mode Access Point (Hotspot Mandiri dari ESP)
#define AP_DEFAULT_SSID         "SmartPSU-AP"
#define AP_DEFAULT_PASSWORD     "12345678"
#define AP_DEFAULT_IP           IPAddress(192, 168, 4, 1)

#define OTA_AUTH_PASSWORD        ""                    // Kosongkan jika tanpa password OTA, atau isi misal "admin123"

#ifdef __cplusplus
extern "C" {
#endif

// Inisialisasi WiFi (AP + STA) & ArduinoOTA
void ota_init(const char* ssid = NULL, const char* password = NULL, const char* ap_ssid = NULL, const char* ap_pass = NULL);

// Handler yang harus dipanggil di loop() utama
void ota_handle(void);

// Status helper
bool ota_is_wifi_connected(void);
const char* ota_get_ip(void);
const char* ota_get_hostname(void);
int8_t ota_get_rssi(void);

// Cetak informasi WiFi & OTA ke Serial
void ota_print_info(void);

#ifdef __cplusplus
}
#endif

#endif // OTA_HANDLER_H
