#ifndef ADS1115_H
#define ADS1115_H

#include <Arduino.h>
#include <Wire.h>

#ifdef __cplusplus
extern "C" {
#endif
 
// ================= ADS1115 CONFIGURATION =================
#define ADS1115_DEFAULT_ADDR    0x48  // Alamat default I2C ADS1115 (ADDR ke GND)
#define ADS_VOLTS_PER_BIT       0.000125f // PGA +/-4.096V -> 1 LSB = 0.125 mV

// Faktor Kalibrasi Rasio Voltage Divider (Fine-Tuned)
#define ADS_RATIO_A1            5.5838f // Dikalibrasi untuk A1 (D- QC 3.0)
#define ADS_RATIO_A2            5.5649f // Dikalibrasi untuk A2 (D+ QC 3.0)
#define ADS_RATIO_A3            5.5838f // Rasio default untuk A3 (AVO / Multitester)

// Struktur Data Hasil Baca ADS1115
typedef struct {
    float vadc;     // Tegangan langsung di pin ADC (V)
    float vin;      // Tegangan sumber setelah dikali rasio divider (V)
    int16_t raw;    // Nilai raw 16-bit ADC
} ads1115_channel_t;

typedef struct {
    ads1115_channel_t a0; // A0 (Aux / Spare)
    ads1115_channel_t a1; // A1 (QC 3.0 D-)
    ads1115_channel_t a2; // A2 (QC 3.0 D+)
    ads1115_channel_t a3; // A3 (AVO Digital / Smart Tester)
} ads1115_data_t;

// ================= FUNCTION PROTOTYPES =================
bool ads1115_init(uint8_t addr);
void ads1115_update(void);
int16_t ads1115_read_raw(uint8_t channel);
float ads1115_read_voltage(uint8_t channel, int samples);
ads1115_data_t ads1115_read_all(void);
uint8_t ads1115_get_address(void);
bool ads1115_is_connected(void);

#ifdef __cplusplus
}
#endif

#endif // ADS1115_H
