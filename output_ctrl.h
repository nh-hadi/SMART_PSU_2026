#ifndef OUTPUT_CTRL_H
#define OUTPUT_CTRL_H

#include <Arduino.h>
#include "pin_config.h"

#ifdef __cplusplus
extern "C" {
#endif

// Inisialisasi pin GPIO untuk Output
void output_init(void);

// Kontrol MOSFET
void output_set_mosfet(bool state);
bool output_get_mosfet(void);

// Kontrol Relay 1
void output_set_relay1(bool state);
bool output_get_relay1(void);

// Kontrol Relay 2
void output_set_relay2(bool state);
bool output_get_relay2(void);

// Kontrol Semua Output Sekaligus
void output_set_all(bool state);

#ifdef __cplusplus
}
#endif

#endif // OUTPUT_CTRL_H
