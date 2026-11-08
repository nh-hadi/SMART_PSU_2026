#include "ina3221.h"

static uint8_t s_inaAddress = INA3221_DEFAULT_ADDR;

uint8_t ina3221_init(uint8_t sda_pin, uint8_t scl_pin) {
    Wire.begin(sda_pin, scl_pin);

    // Auto-detect alamat INA3221 (pilihan: 0x40, 0x41, 0x42, 0x43)
    const uint8_t possibleAddrs[] = { 0x40, 0x41, 0x42, 0x43 };
    for (uint8_t i = 0; i < 4; i++) {
        Wire.beginTransmission(possibleAddrs[i]);
        if (Wire.endTransmission() == 0) {
            s_inaAddress = possibleAddrs[i];
            break;
        }
    }

    // Konfigurasi Register 0x00 INA3221:
    // Bit 15: 0 (No Reset)
    // Bit 14: 1 (Enable CH1)
    // Bit 13: 1 (Enable CH2)
    // Bit 12: 1 (Enable CH3)
    // Bit 11-9: 000 (Averaging 1 sample) atau 001 (4 samples)
    // Bit 8-6: 100 (Vbus conv time 1.1ms)
    // Bit 5-3: 100 (Vshunt conv time 1.1ms)
    // Bit 2-0: 111 (Shunt and Bus, Continuous Mode)
    // Nilai = 0x7127 (atau 0x7000 default)
    Wire.beginTransmission(s_inaAddress);
    Wire.write(REG_INA3221_CONFIG);
    Wire.write(0x71); // MSB: Aktifkan CH1, CH2, CH3
    Wire.write(0x27); // LSB: Mode Continuous Bus + Shunt
    Wire.endTransmission();

    return s_inaAddress;
}

uint8_t ina3221_get_address(void) {
    return s_inaAddress;
}

int16_t ina3221_read_register(uint8_t reg) {
    Wire.beginTransmission(s_inaAddress);
    Wire.write(reg);
    if (Wire.endTransmission() != 0) {
        return 0; // Komunikasi I2C gagal
    }

    Wire.requestFrom(s_inaAddress, (uint8_t)2);
    if (Wire.available() == 2) {
        return (Wire.read() << 8) | Wire.read();
    }
    return 0;
}

// Membaca Bus Voltage (Volt)
// 13-bit data, bit 0-2 tidak dipakai (geser kanan 3), LSB = 8mV
float ina3221_get_bus_voltage(uint8_t busReg) {
    int16_t raw = ina3221_read_register(busReg);
    return ((raw >> 3) * 8.0f) / 1000.0f;
}

// Membaca Shunt Voltage (milliVolt)
// 13-bit data, bit 0-2 tidak dipakai (geser kanan 3), LSB = 40uV (0.04mV)
float ina3221_get_shunt_voltage_mv(uint8_t shuntReg) {
    int16_t raw = ina3221_read_register(shuntReg);
    return (raw >> 3) * 0.04f;
}

// Menghitung Arus (mA) = Vshunt (mV) / Rshunt (Ohm)
float ina3221_get_current_ma(uint8_t shuntReg) {
    float shuntVoltage_mV = ina3221_get_shunt_voltage_mv(shuntReg);
    return shuntVoltage_mV / (float)SHUNT_RESISTOR_OHM;
}

// Membaca seluruh channel sekaligus ke dalam struct
ina3221_data_t ina3221_read_all(void) {
    ina3221_data_t data;

    // CH1
    data.ch1.busVoltage_V = ina3221_get_bus_voltage(REG_INA3221_CH1_BUS_V);
    data.ch1.shuntVoltage_mV = ina3221_get_shunt_voltage_mv(REG_INA3221_CH1_SHUNT_V);
    data.ch1.current_mA = ina3221_get_current_ma(REG_INA3221_CH1_SHUNT_V);

    // CH2
    data.ch2.busVoltage_V = ina3221_get_bus_voltage(REG_INA3221_CH2_BUS_V);
    data.ch2.shuntVoltage_mV = ina3221_get_shunt_voltage_mv(REG_INA3221_CH2_SHUNT_V);
    data.ch2.current_mA = ina3221_get_current_ma(REG_INA3221_CH2_SHUNT_V);

    // CH3
    data.ch3.busVoltage_V = ina3221_get_bus_voltage(REG_INA3221_CH3_BUS_V);
    data.ch3.shuntVoltage_mV = ina3221_get_shunt_voltage_mv(REG_INA3221_CH3_SHUNT_V);
    data.ch3.current_mA = ina3221_get_current_ma(REG_INA3221_CH3_SHUNT_V);

    return data;
}

void ina3221_scan_i2c_string(char* outBuf, size_t maxLen) {
    if (!outBuf || maxLen == 0) return;
    outBuf[0] = '\0';

    int count = 0;
    for (uint8_t addr = 1; addr < 127; addr++) {
        Wire.beginTransmission(addr);
        if (Wire.endTransmission() == 0) {
            char hexPart[12];
            snprintf(hexPart, sizeof(hexPart), "%s0x%02X", (count > 0 ? "," : ""), addr);
            strncat(outBuf, hexPart, maxLen - strlen(outBuf) - 1);
            count++;
        }
    }

    if (count == 0) {
        strncpy(outBuf, "NONE", maxLen - 1);
    }
}
