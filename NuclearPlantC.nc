#include <Timer.h>
#include "NuclearPlant.h"

module NuclearPlantC {
	uses interface Boot;
	uses interface Timer<TMilli> as Timer0;
	uses interface RadioInterface;
	uses interface Queue<SensorInformation> as DataQueue;
	uses interface SensorInterface as TemperatureSensor;
	uses interface SensorInterface as RadiationSensor;
	uses interface SensorInterface as SmokeSensor;

	provides interface NuclearPlantInterface;
}

implementation {
	uint16_t currentTMeasure = DEFAULT_TMEASURE;
	bool haltSend = FALSE;

	event void Boot.booted() {
		dbg("Boot", "Boot starting\n");
		call RadioInterface.startRadio();
	}

	event void Timer0.fired() {
		uint16_t radiation = call RadiationSensor.readValue();
		uint16_t temperature = call TemperatureSensor.readValue();
		uint16_t smoke = call SmokeSensor.readValue();
		dbg("CollectionDebug", "Starting collection\n");
		if (TOS_NODE_ID == 0) {
			signal RadioInterface.receiveData(TOS_NODE_ID, radiation, temperature, smoke);
		} else {
			if (!(call DataQueue.empty()) || haltSend) {
				SensorInformation info;
				info.radiation = radiation;
				info.temperature = temperature;
				info.smoke = smoke;
				if (call DataQueue.size() == call DataQueue.maxSize()) {  // discard older message, because most recent messages are more important, older messages can be used to create a chart
					call DataQueue.dequeue();
					dbg("CollectionDebug", "Discarding old stashed data.\n");
				}
				call DataQueue.enqueue(info);
				dbg("Collection", "Stashing data.\n");
			} else {
				dbg("Collection", "Sending data.\n");
				call RadioInterface.sendData(TOS_NODE_ID, radiation, temperature, smoke);
			}
		}
	}
	
	event void RadioInterface.sendDataDone() {
		if (!(call DataQueue.empty())) {
			SensorInformation info = call DataQueue.dequeue();
			dbg("Collection", "Sending stashed data.\n");
			call RadioInterface.sendData(TOS_NODE_ID, info.radiation, info.temperature, info.smoke);
		}
	}

	event void RadioInterface.receiveData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke) {
		dbg("Receive", "Received\n");
	}

	event void RadioInterface.receiveDiffuse(uint16_t tMeasure) {
	}

	command void NuclearPlantInterface.startCollect() {
		if (haltSend) {
			haltSend = FALSE;
		}
		call Timer0.startPeriodic(currentTMeasure);
		dbg("CollectionDebug", "Timer started\n");
	}

	command void NuclearPlantInterface.haltSendData() {
		haltSend = TRUE;
	}

	command uint16_t NuclearPlantInterface.getTMeasure() {
		return currentTMeasure;
	}

	command void NuclearPlantInterface.setTMeasure(uint16_t tMeasure) {
		currentTMeasure = tMeasure;
		if (call Timer0.isRunning()) {
			call Timer0.stop();
			call Timer0.startPeriodic(currentTMeasure);
		}
		dbg("CollectionDebug", "New tMeasure\n");
	}
}
