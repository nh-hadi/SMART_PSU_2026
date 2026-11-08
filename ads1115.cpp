#include "ads1115.h"

static uint8_t g_ads_addr = ADS1115_DEFAULT_ADDR;
static bool g_ads_connected = false;

// State Machine Non-Blocking berbasis millis()
enum AdsState {
    ADS_TRIGGER,
    ADS_WAIT_CONVERSION
};

static AdsState g_state = ADS_TRIGGER;
static uint8_t g_currentChannel = 0;
static unsigned long g_lastTriggerMillis = 0;
static const unsigned long ADS_CONVERSION_TIME_MS = 2; // Konversi 860 SPS butuh ~1.16ms, 2ms sangat aman

static ads1115_data_t g_cachedData = {};

static void ads1115_start_conversion(uint8_t channel) {
    if (!g_ads_connected || channel > 3) return;

    // Config Register:
    // - OS = 1 (Start conversion)
    // - MUX = 100 (A0), 101 (A1), 110 (A2), 111 (A3)
    // - PGA = 001 (+/- 4.096V)
    // - MODE = 1 (Single-shot)
    // - DR = 111 (860 SPS - Tercepat)
    // - COMP_QUE = 11 (Disable comparator)
    uint16_t config = 0x8000;
    config |= ((0x04 | channel) << 12);
    config |= (0x01 << 9);
    config |= (0x01 << 8);
    config |= (0x07 << 5);
    config |= 0x0003;

    Wire.beginTransmission(g_ads_addr);
    Wire.write(0x01);
    Wire.write((uint8_t)(config >> 8));
    Wire.write((uint8_t)(config & 0xFF));
    Wire.endTransmission();
}

static int16_t ads1115_fetch_result(void) {
    if (!g_ads_connected) return 0;

    Wire.beginTransmission(g_ads_addr);
    Wire.write(0x00);
    if (Wire.endTransmission() != 0) return 0;

    Wire.requestFrom((uint8_t)g_ads_addr, (uint8_t)2);
    if (Wire.available() == 2) {
        return (Wire.read() << 8) | Wire.read();
    }
    return 0;
}

// Inisialisasi ADS1115 dengan Auto-Detect Alamat (0x48 - 0x4B)
bool ads1115_init(uint8_t addr) {
    g_ads_addr = addr;
    const uint8_t possibleAdsAddrs[] = { 0x48, 0x49, 0x4A, 0x4B };
    g_ads_connected = false;

    for (uint8_t i = 0; i < 4; i++) {
        Wire.beginTransmission(possibleAdsAddrs[i]);
        if (Wire.endTransmission() == 0) {
            g_ads_addr = possibleAdsAddrs[i];
            g_ads_connected = true;
            break;
        }
    }

    memset(&g_cachedData, 0, sizeof(g_cachedData));
    g_state = ADS_TRIGGER;
    g_currentChannel = 0;
    g_lastTriggerMillis = 0;

    if (g_ads_connected) {
        ads1115_start_conversion(0);
        g_state = ADS_WAIT_CONVERSION;
        g_lastTriggerMillis = millis();
    }
    return g_ads_connected;
}

// State Machine Update: Dipanggil berkala tanpa delay sedikitpun
void ads1115_update(void) {
    if (!g_ads_connected) return;

    unsigned long now = millis();

    switch (g_state) {
        case ADS_TRIGGER:
            ads1115_start_conversion(g_currentChannel);
            g_lastTriggerMillis = now;
            g_state = ADS_WAIT_CONVERSION;
            break;

        case ADS_WAIT_CONVERSION:
            if (now - g_lastTriggerMillis >= ADS_CONVERSION_TIME_MS) {
                int16_t raw = ads1115_fetch_result();
                if (raw < 0) raw = 0;
                float vadc = (float)raw * ADS_VOLTS_PER_BIT;

                switch (g_currentChannel) {
                    case 0: // A0 (Spare)
                        g_cachedData.a0.raw = raw;
                        g_cachedData.a0.vadc = vadc;
                        g_cachedData.a0.vin = vadc;
                        break;
                    case 1: // A1 (QC 3.0 D-)
                        g_cachedData.a1.raw = raw;
                        g_cachedData.a1.vadc = vadc;
                        g_cachedData.a1.vin = (vadc > 0.30f) ? (vadc * ADS_RATIO_A1) : 0.0f;
                        break;
                    case 2: // A2 (QC 3.0 D+)
                        g_cachedData.a2.raw = raw;
                        g_cachedData.a2.vadc = vadc;
                        g_cachedData.a2.vin = (vadc > 0.30f) ? (vadc * ADS_RATIO_A2) : 0.0f;
                        break;
                    case 3: // A3 (AVO Digital / Smart Tester)
                        g_cachedData.a3.raw = raw;
                        g_cachedData.a3.vadc = vadc;
                        g_cachedData.a3.vin = (vadc > 0.30f) ? (vadc * ADS_RATIO_A3) : 0.0f;
                        break;
                }

                // Ganti channel berikutnya dan langsung trigger
                g_currentChannel = (g_currentChannel + 1) % 4;
                ads1115_start_conversion(g_currentChannel);
                g_lastTriggerMillis = now;
            }
            break;
    }
}

// Membaca Raw langsung dari cache tanpa delay
int16_t ads1115_read_raw(uint8_t channel) {
    switch (channel) {
        case 0: return g_cachedData.a0.raw;
        case 1: return g_cachedData.a1.raw;
        case 2: return g_cachedData.a2.raw;
        case 3: return g_cachedData.a3.raw;
        default: return 0;
    }
}

// Membaca Vadc langsung dari cache tanpa delay
float ads1115_read_voltage(uint8_t channel, int samples) {
    (void)samples;
    switch (channel) {
        case 0: return g_cachedData.a0.vadc;
        case 1: return g_cachedData.a1.vadc;
        case 2: return g_cachedData.a2.vadc;
        case 3: return g_cachedData.a3.vadc;
        default: return 0.0f;
    }
}

// Mengambil seluruh channel ADS1115 secara instan (0 milidetik delay)
ads1115_data_t ads1115_read_all(void) {
    ads1115_update(); // Lakukan update non-blocking jika waktunya tiba
    return g_cachedData;
}

uint8_t ads1115_get_address(void) {
    return g_ads_addr;
}

bool ads1115_is_connected(void) {
    return g_ads_connected;
}


