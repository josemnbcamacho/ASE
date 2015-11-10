#ifndef RADIO_H
#define RADIO_H

enum {
	MAX_JOINRESPONSES = 10,
	MAX_DATAQUEUE = 20,
	TIMER_JOIN_COLLECT = 2000,
	TIME_FAILURE_ACK = 2000,
	TIME_FAILURE_JOIN = 2000,
	MAX_NHOPS = 65535
};

typedef uint8_t radio_id_t;

// messages
#include "RadioMessages.h"

// data holders
typedef struct ParentCandidate {
	am_addr_t addr;
	uint16_t nhops;
	uint16_t tMeasure;
} ParentCandidate;


typedef struct MessageData {
	uint8_t len;
	am_addr_t addr;
	uint8_t data[8];
} MessageData;

#endif
