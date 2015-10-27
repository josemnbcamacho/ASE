interface RadioInterface {
	command error_t sendDiffuse(message_t* msg);
	command error_t sendCollect(message_t* msg);
	event void sendDone(message_t* msg, error_t error);
	event message_t* receiveCollect(message_t* msg, void* payload, uint8_t len);
} 
