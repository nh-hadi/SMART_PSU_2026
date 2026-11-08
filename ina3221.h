#ifndef INA3221_H
#define INA3221_H

#include <Arduino.h>
#include <Wire.h>

#ifdef __cplusplus
extern "C" {
#endif

// ================= INA3221 CONFIGURATION =================
#define INA3221_DEFAULT_ADDR    0x40  // Alamat I2C terdeteksi (A0 default board = 0x43)
#define SHUNT_RESISTOR_OHM      0.01  // R010 = 0.01 Ohm

// Register INA3221
#define REG_INA3221_CONFIG      0x00
#define REG_INA3221_CH1_SHUNT_V 0x01
#define REG_INA3221_CH1_BUS_V   0x02
#define REG_INA3221_CH2_SHUNT_V 0x03
#define REG_INA3221_CH2_BUS_V   0x04
#define REG_INA3221_CH3_SHUNT_V 0x05
#define REG_INA3221_CH3_BUS_V   0x06

// Data structure per-channel
typedef struct {
    float busVoltage_V;     // Tegangan Bus (Volt)
    float shuntVoltage_mV;  // Tegangan Shunt (mV)
    float current_mA;       // Arus (mA)
} ina3221_channel_t;

// Data structure 3-Channel INA3221
typedef struct {
    ina3221_channel_t ch1;  // CH1: Tegangan Luar
    ina3221_channel_t ch2;  // CH2: Step Down Adjust
    ina3221_channel_t ch3;  // CH3: QC 3.0
} ina3221_data_t;

// Function Prototypes (C-style)
uint8_t ina3221_init(uint8_t sda_pin, uint8_t scl_pin);
uint8_t ina3221_get_address(void);
int16_t ina3221_read_register(uint8_t reg);
float ina3221_get_bus_voltage(uint8_t busReg);
float ina3221_get_shunt_voltage_mv(uint8_t shuntReg);
float ina3221_get_current_ma(uint8_t shuntReg);
ina3221_data_t ina3221_read_all(void);
void ina3221_scan_i2c_string(char* outBuf, size_t maxLen);

#ifdef __cplusplus
}
#endif

#endif // INA3221_H
