#ifndef RADIO_H
#define RADIO_H

typedef uint8_t radio_id_t;

typedef nx_struct BlinkToRadioMsg {
	nx_uint16_t nodeid;
	nx_uint16_t counter;
} BlinkToRadioMsg;

#endif
