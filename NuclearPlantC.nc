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
		
	}
	
	event void RadioInterface.sendDone(message_t* msg, error_t error) {
	}

	event void RadioInterface.receiveData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke) {
		dbg("Receive", "Received");
	}

	event void RadioInterface.receiveDiffuse(uint16_t tMeasure) {
	}
}
