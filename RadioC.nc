#include "Radio.h"

generic configuration RadioC(radio_id_t RadioId) {
	provides {
		interface RadioInterface;
	}
	uses interface NuclearPlantInterface as App;
}

implementation {
	components ActiveMessageC;
	components new AMSenderC(RadioId);
	components new AMReceiverC(RadioId);
	components RadioP;
	components new QueueC(ParentCandidate, MAX_JOINRESPONSES);
	components new QueueC(MessageData, MAX_DATAQUEUE) as OutQueue;
	components new QueueC(MessageData, MAX_DATAQUEUE) as PriorityQueue;
	components new TimerMilliC();
	
	RadioP.NuclearPlant = App;

	RadioInterface = RadioP;

	RadioP.Packet -> AMSenderC;
	RadioP.AMPacket -> AMSenderC;
	RadioP.AMSend -> AMSenderC;
	RadioP.AMControl -> ActiveMessageC;
	RadioP.Receive -> AMReceiverC;
	RadioP.Queue -> QueueC;
	RadioP.OutQueue -> OutQueue;
	RadioP.PriorityQueue -> PriorityQueue;
	RadioP.MilliTimer -> TimerMilliC;
}
