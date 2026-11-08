
/*
 * =====================================================================
 * Smart PSU v1.0.0
 * Modular C-Style Architecture
 * 
 * Modul:
 *  - pin_config.h   : Konfigurasi Pin dan level logika GPIO
 *  - output_ctrl    : Driver Output (MOSFET & Dual Relay)
 *  - ina3221        : Driver Sensor INA3221 (3-Channel I2C)
 *  - ads1115        : Driver ADC ADS1115 (4-Channel 16-Bit I2C)
 *  - ota_handler    : Manajemen WiFi & ArduinoOTA (Hostname: smartpsu)
 *  - udp_handler    : UDP Telemetry Broadcaster & HTTP Web OTA Updater
 * =====================================================================
 */

#include <Arduino.h>
#include "pin_config.h"
#include "output_ctrl.h"
#include "ina3221.h"
#include "ads1115.h"
#include "ota_handler.h"
#include "udp_handler.h"

// Interval pembacaan sensor secara non-blocking (ms) - 100ms Ultra Fast
const unsigned long SENSOR_INTERVAL_MS = 100;
static unsigned long lastSensorReadTime = 0;

void printHelp() {
  Serial.println("\n--- Perintah Serial yang Tersedia ---");
  Serial.println("  mosfet on   / mosfet off");
  Serial.println("  relay1 on   / relay1 off");
  Serial.println("  relay2 on   / relay2 off");
  Serial.println("  all on      / all off");
  Serial.println("  wifi        / ota / ip     (Info Jaringan & OTA)");
  Serial.println("  status      / help");
  Serial.println("--------------------------------------\n");
}

void printStatus() {
  Serial.println("\n=== STATUS HARDWARE ===");
  Serial.printf(" MOSFET  (GPIO %d) : %s\n", PIN_MOSFET, output_get_mosfet() ? "ON" : "OFF");
  Serial.printf(" RELAY 1 (GPIO %d) : %s\n", PIN_RELAY_1, output_get_relay1() ? "ON" : "OFF");
  Serial.printf(" RELAY 2 (GPIO %d) : %s\n", PIN_RELAY_2, output_get_relay2() ? "ON" : "OFF");
  Serial.printf(" Hostname          : %s.local\n", ota_get_hostname());
  Serial.printf(" WiFi Status       : %s (IP: %s)\n", ota_is_wifi_connected() ? "CONNECTED" : "DISCONNECTED", ota_get_ip());
  Serial.println("=======================\n");
}

// Handler perintah Serial Masuk
void handleSerialCommands() {
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    cmd.toLowerCase();

    if (cmd.length() == 0) return;

    if (cmd == "mosfet on" || cmd == "m on" || cmd == "m1") {
      output_set_mosfet(true);
      Serial.println("[MOSFET] -> ON");
    } else if (cmd == "mosfet off" || cmd == "m off" || cmd == "m0") {
      output_set_mosfet(false);
      Serial.println("[MOSFET] -> OFF");
    } else if (cmd == "relay1 on" || cmd == "r1 on" || cmd == "r11") {
      output_set_relay1(true);
      Serial.println("[RELAY 1] -> ON");
    } else if (cmd == "relay1 off" || cmd == "r1 off" || cmd == "r10") {
      output_set_relay1(false);
      Serial.println("[RELAY 1] -> OFF");
    } else if (cmd == "relay2 on" || cmd == "r2 on" || cmd == "r21") {
      output_set_relay2(true);
      Serial.println("[RELAY 2] -> ON");
    } else if (cmd == "relay2 off" || cmd == "r2 off" || cmd == "r20") {
      output_set_relay2(false);
      Serial.println("[RELAY 2] -> OFF");
    } else if (cmd == "all on") {
      output_set_all(true);
      Serial.println("[ALL] -> ON");
    } else if (cmd == "all off") {
      output_set_all(false);
      Serial.println("[ALL] -> OFF");
    } else if (cmd == "wifi" || cmd == "ota" || cmd == "ip") {
      ota_print_info();
    } else if (cmd == "status") {
      printStatus();
    } else if (cmd == "help") {
      printHelp();
    } else {
      Serial.printf("[ERROR] Perintah '%s' tidak dikenal. Ketik 'help' untuk panduan.\n", cmd.c_str());
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(500); // Beri jeda singkat untuk stabilitas tegangan & Serial

  // Inisialisasi I2C Bus & Sensor INA3221 (dengan auto-detect alamat 0x40-0x43)
  uint8_t inaAddr = ina3221_init(PIN_I2C_SDA, PIN_I2C_SCL);

  // Inisialisasi Sensor ADS1115
  bool adsOk = ads1115_init(ADS1115_DEFAULT_ADDR);

  // Inisialisasi Output (MOSFET & Dual Relay)
  output_init();

  // Inisialisasi Modul WiFi & ArduinoOTA (Hostname: smartpsu)
  ota_init();

  // Inisialisasi UDP Telemetry & Web OTA Server
  udp_telemetry_init();

  Serial.println("\n==============================================");
  Serial.printf ("       SMART PSU v1.0.0 [%s]          \n", BOARD_NAME);
  Serial.printf ("  INA3221 I2C Address : 0x%02X\n", inaAddr);
  Serial.printf ("  ADS1115 Status      : %s (0x%02X)\n", adsOk ? "ONLINE" : "OFFLINE/NOT FOUND", ADS1115_DEFAULT_ADDR);
  Serial.printf ("  OTA Hostname        : %s.local\n", ota_get_hostname());
  Serial.printf ("  UDP Telemetry Port  : %d\n", UDP_DEFAULT_PORT);
  Serial.println("==============================================");
  printHelp();
  printStatus();
}

void loop() {
  // 1. Tangani proses OTA Update secara rutin di background
  ota_handle();

  // 2. Tangani paket UDP Telemetry & HTTP Web Server
  udp_telemetry_handle();

  // 3. Update State Machine Sensor ADS1115 secara Non-Blocking (0 Delay)
  ads1115_update();

  // 4. Tangani input kontrol Serial
  handleSerialCommands();

  // 5. Monitoring berkala sensor INA3221 & ADS1115 secara non-blocking
  unsigned long currentMillis = millis();
  if (currentMillis - lastSensorReadTime >= SENSOR_INTERVAL_MS) {
    lastSensorReadTime = currentMillis;

    // Baca seluruh channel INA3221
    ina3221_data_t sensorData = ina3221_read_all();

    // Baca seluruh channel ADS1115
    ads1115_data_t adsData = ads1115_read_all();

    // Broadcast ke Flutter App via UDP
    udp_broadcast_telemetry(&sensorData, &adsData);

    // Cetak format Serial
    Serial.printf("[INA] CH1:%5.2fV %6.1fmA | CH2:%5.2fV %6.1fmA | CH3:%5.2fV %6.1fmA\n",
                  sensorData.ch1.busVoltage_V, sensorData.ch1.current_mA,
                  sensorData.ch2.busVoltage_V, sensorData.ch2.current_mA,
                  sensorData.ch3.busVoltage_V, sensorData.ch3.current_mA);

    Serial.printf("[ADS] A1(D-):%5.2fV | A2(D+):%5.2fV | A3(AVO):%5.2fV || [OUT] M:%d R1:%d R2:%d\n",
                  adsData.a1.vin, adsData.a2.vin, adsData.a3.vin,
                  output_get_mosfet() ? 1 : 0,
                  output_get_relay1() ? 1 : 0,
                  output_get_relay2() ? 1 : 0);
  }
}
