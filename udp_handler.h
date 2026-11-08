#ifndef UDP_HANDLER_H
#define UDP_HANDLER_H

#include <Arduino.h>
#include "ina3221.h"
#include "ads1115.h"

#define UDP_DEFAULT_PORT 4210

#ifdef __cplusplus
extern "C" {
#endif

// Inisialisasi UDP Telemetry & HTTP Web OTA Updater
void udp_telemetry_init(uint16_t port = UDP_DEFAULT_PORT);

// Handle penerimaan paket UDP & Web Server di loop()
void udp_telemetry_handle(void);

// Broadcast data sensor ke semua client (Flutter App)
void udp_broadcast_telemetry(const ina3221_data_t* inaData, const ads1115_data_t* adsData);

#ifdef __cplusplus
}
#endif

#endif // UDP_HANDLER_H
