generic module RadioP()
{
	provides interface RadioInterface;
	uses {
		interface AMSend;
		interface Receive;
		interface Packet;
		interface AMPacket;
		interface SplitControl as AMControl;
	}
}

implementation
{
	command error_t RadioInterface.sendDiffuse(message_t* msg) {
		return SUCCESS;
	}
	command error_t RadioInterface.sendCollect(message_t* msg) {
		return SUCCESS;
	}
	event void AMControl.startDone(error_t err) {
	}
	event void AMControl.stopDone(error_t err) {
	}
	event void AMSend.sendDone(message_t* msg, error_t error) {
	}
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		return msg;
	}
} 
