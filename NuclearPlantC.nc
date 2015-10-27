#include <Timer.h>
#include "NuclearPlant.h"

module NuclearPlantC {
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface RadioInterface;
}

implementation {
	event void Boot.booted() {
		dbg("Boot", "Boot starting");
	}

	event void Timer0.fired() {
		RadioInterface.sendData(10, 10, 10);
	}
	
	event void RadioInterface.sendDone(message_t* msg, error_t error) {
	}

	event message_t* RadioInterface.receiveCollect(message_t* msg, void* payload, uint8_t len) {
		dbg("Receive", "Received");
		return msg;
	}
}
