#include "output_ctrl.h"

static bool s_mosfetState = false;
static bool s_relay1State = false;
static bool s_relay2State = false;

void output_init(void) {
    // Inisialisasi Pin MOSFET
    pinMode(PIN_MOSFET, OUTPUT);
    output_set_mosfet(false);

    // Inisialisasi Pin Relay 1 & 2
    pinMode(PIN_RELAY_1, OUTPUT);
    pinMode(PIN_RELAY_2, OUTPUT);
    output_set_relay1(false);
    output_set_relay2(false);
}

void output_set_mosfet(bool state) {
    s_mosfetState = state;
    digitalWrite(PIN_MOSFET, s_mosfetState ? HIGH : LOW);
}

bool output_get_mosfet(void) {
    return s_mosfetState;
}

void output_set_relay1(bool state) {
    s_relay1State = state;
    digitalWrite(PIN_RELAY_1, s_relay1State ? RELAY_ACTIVE_LEVEL : RELAY_INACTIVE_LEVEL);
}

bool output_get_relay1(void) {
    return s_relay1State;
}

void output_set_relay2(bool state) {
    s_relay2State = state;
    digitalWrite(PIN_RELAY_2, s_relay2State ? RELAY_ACTIVE_LEVEL : RELAY_INACTIVE_LEVEL);
}

bool output_get_relay2(void) {
    return s_relay2State;
}

void output_set_all(bool state) {
    output_set_mosfet(state);
    output_set_relay1(state);
    output_set_relay2(state);
}
