#include "Radio.h"

interface RadioInterface {
	command void startRadio();
	command error_t sendDiffuse(uint16_t tMeasure);
	command error_t sendData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke);
	command error_t sendJoin();
	command void sendACK();
	event void sendDataDone();
	event void receiveData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke);
	event void receiveDiffuse(uint16_t tMeasure);
	command error_t sendMessage(am_addr_t destination, uint8_t* data, uint8_t len);
	command void dispatch(MessageData msg);
} 
