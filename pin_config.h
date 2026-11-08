#ifndef PIN_CONFIG_H
#define PIN_CONFIG_H

#include <Arduino.h>

// =======================================================
// AUTOMATIC BOARD DETECTION & PIN DEFINITIONS
// =======================================================

#if defined(ESP8266)
  // -----------------------------------------------------
  // TARGET: ESP8266 (ESP-12E / ESP-12F / NodeMCU Amica)
  // -----------------------------------------------------
  #define BOARD_NAME          "ESP8266"

  // 1. Output Switching & Proteksi
  #define PIN_MOSFET          15  // GPIO 15 (D8) - Saklar MOSFET Proteksi / Output
  #define PIN_RELAY_1         12  // GPIO 12 (D6) - Relay Channel 1
  #define PIN_RELAY_2         13  // GPIO 13 (D7) - Relay Channel 2

  // 2. I2C Bus (Sensor INA3221 & ADC ADS1115)
  #define PIN_I2C_SDA         4   // GPIO 4  (D2) - I2C SDA
  #define PIN_I2C_SCL         5   // GPIO 5  (D1) - I2C SCL

  // 3. Smart Multitester & Indikator Suara
  #define PIN_TESTER_DIODE    14  // GPIO 14 (D5) - Smart Multitester Mode Dioda / Continuity
  #define PIN_BUZZER          16  // GPIO 16 (D0) - Buzzer Alarm / Beep Alert

  // 4. User Interface (LED Addressable & Tombol Fisik)
  #define PIN_WS2812B_LED     2   // GPIO 2  (D4 / TXD1) - LED Addressable WS2812B NeoPixel
  #define PIN_BUTTON          0   // GPIO 0  (D3 / FLASH) - Push Button (Active LOW)

  // 5. Komunikasi Serial
  #define PIN_UART_TX         1   // GPIO 1  (TX) - Serial TX ke HP/PC
  #define PIN_UART_RX         3   // GPIO 3  (RX) - Serial RX dari HP/PC

#elif defined(ESP32)
  // -----------------------------------------------------
  // TARGET: ESP32 (ESP32-WROOM-32 / DevKit V1 30/38 Pin)
  // -----------------------------------------------------
  #define BOARD_NAME          "ESP32"

  // 1. Output Switching & Proteksi
  #define PIN_MOSFET          19  // GPIO 19 - Saklar MOSFET Proteksi / Output
  #define PIN_RELAY_1         18  // GPIO 18 - Relay Channel 1
  #define PIN_RELAY_2         5   // GPIO 5  - Relay Channel 2

  // 2. I2C Bus (Hardware I2C Wire)
  #define PIN_I2C_SDA         21  // GPIO 21 - Default I2C SDA ESP32
  #define PIN_I2C_SCL         22  // GPIO 22 - Default I2C SCL ESP32

  // 3. Smart Multitester & Indikator Suara
  #define PIN_TESTER_DIODE    23  // GPIO 23 - Smart Multitester Mode Dioda / Continuity
  #define PIN_BUZZER          4   // GPIO 4  - Buzzer Alarm / Beep Alert (PWM/DAC/Tone)

  // 4. User Interface (LED Addressable & Tombol Fisik)
  #define PIN_WS2812B_LED     15  // GPIO 15 - LED Addressable WS2812B NeoPixel
  #define PIN_BUTTON          0   // GPIO 0  - BOOT Button onboard (Active LOW)

  // 5. Komunikasi Serial (Hardware UART0)
  #define PIN_UART_TX         1   // GPIO 1  (TX0)
  #define PIN_UART_RX         3   // GPIO 3  (RX0)

#else
  #error "Board tidak didukung! Pilih board ESP8266 atau ESP32 di Arduino IDE."
#endif

// =======================================================
// ADS1115 ADC CHANNELS MAPPING
// =======================================================
#define ADS_CH_QC_DM        1   // ADS1115 A1 - Baca Tegangan D- QC 3.0
#define ADS_CH_QC_DP        2   // ADS1115 A2 - Baca Tegangan D+ QC 3.0
#define ADS_CH_AVO          3   // ADS1115 A3 - AVO Digital (Tegangan Eksternal)

// =======================================================
// INA3221 CHANNELS MAPPING
// =======================================================
#define INA_CH_EXTERNAL     1   // Channel 1 - Tegangan / Arus dari luar
#define INA_CH_STEPDOWN     2   // Channel 2 - Tegangan / Arus Step Down Adjust
#define INA_CH_QC30         3   // Channel 3 - Tegangan / Arus QC 3.0

// =======================================================
// LOGIC & TRIGGER LEVEL DEFINITIONS
// =======================================================
// Level Aktif Relay (Modul Relay Active LOW)
#define RELAY_ACTIVE_LEVEL    LOW
#define RELAY_INACTIVE_LEVEL  HIGH

// Level Aktif MOSFET (N-Channel Logic High)
#define MOSFET_ACTIVE_LEVEL   HIGH
#define MOSFET_INACTIVE_LEVEL LOW

// Level Aktif Tombol (Pull-up ke GND)
#define BUTTON_PRESSED_LEVEL  LOW

#endif // PIN_CONFIG_H

