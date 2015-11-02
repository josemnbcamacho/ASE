interface RadioInterface {
	command error_t sendDiffuse(uint16_t tMeasure);
	command error_t sendData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke);
	command error_t sendJoin();
	event void sendDone(message_t* msg, error_t error);
	event void receiveData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke);
	event void receiveDiffuse(uint16_t tMeasure);
} 
