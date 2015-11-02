#ifndef RADIO_H
#define RADIO_H

//messageType: Diffuse=1, JoinResponse=0

typedef uint8_t radio_id_t;

typedef nx_struct CollectMessage {
	nx_uint16_t nodeid;
	nx_uint16_t temperature;
	nx_uint16_t radiation;
	nx_uint16_t smoke;
} CollectMessage;

typedef nx_struct DiffuseMessage {
	nx_uint16_t tMeasure;
	nx_uint8_t messageType : 1;
} DiffuseMessage;

typedef nx_struct JoinMessage {
//empty on purpose
} JoinMessage;

typedef nx_struct JoinResponseMessage {
	nx_uint16_t nhops;
	nx_uint8_t messageType : 1;
} JoinResponseMessage;

#endif
