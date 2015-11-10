#ifndef RADIOMESSAGE_H 
#define RADIOMESSAGE_H

//messageType: Ack=0, Join=1
typedef nx_struct AckMessage {
	nx_uint8_t messageType : 1;
} AckMessage;

typedef nx_struct JoinMessage {
	nx_uint8_t messageType : 1;
} JoinMessage;

//messageType: JoinResponse=0, Diffuse=1
typedef nx_struct DiffuseMessage {
	nx_uint16_t tMeasure;
	nx_uint8_t diffid;
} DiffuseMessage;

typedef nx_struct JoinResponseMessage {
	nx_uint16_t nhops;
	nx_uint8_t diffid;
	nx_uint16_t tMeasure;
} JoinResponseMessage;

typedef nx_struct CollectMessage {
	nx_uint16_t nodeid;
	nx_uint16_t temperature;
	nx_uint16_t radiation;
	nx_uint16_t smoke;
} CollectMessage;

enum {
	AM_DIFFUSEMESSAGE = 6
};

#endif