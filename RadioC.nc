#include "Radio.h"

generic configuration RadioC(radio_id_t RadioId) {
	provides {
		interface RadioInterface;
	}
}

implementation {
	components ActiveMessageC;
	components new AMSenderC(RadioId);
	components new AMReceiverC(RadioId);
	components new RadioP();
	
	RadioInterface = RadioP;

	RadioP.Packet -> AMSenderC;
	RadioP.AMPacket -> AMSenderC;
	RadioP.AMSend -> AMSenderC;
	RadioP.AMControl -> ActiveMessageC;
	RadioP.Receive -> AMReceiverC;
}
