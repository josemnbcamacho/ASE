#ifndef NUCLEARPLANT_H
#define NUCLEARPLANT_H

enum {
	AM_PLANTRADIO = 6,
	DEFAULT_TMEASURE = 10000,
	MAX_PENDING_DATA = 10 // pending data packets
};

typedef struct SensorInformation {
	uint16_t radiation;
	uint16_t temperature;
	uint16_t smoke;
} SensorInformation;

#endif

