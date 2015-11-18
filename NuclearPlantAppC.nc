#include <Timer.h>
#include "NuclearPlant.h"

configuration NuclearPlantAppC {
}
implementation {
	components MainC;
	components NuclearPlantC as App;
	components LocalTimeMilliC;
	components new TimerMilliC() as Timer0;
	components new RadioC(AM_PLANTRADIO);
	components new QueueC(SensorInformation, MAX_PENDING_DATA);
	components TemperatureSensorC;
	components RadiationSensorC;
	components SmokeSensorC;
	
	App.Boot -> MainC;
	App.RadioInterface -> RadioC;
	App.Timer0 -> Timer0;
	App.LocalTime -> LocalTimeMilliC;
	App.DataQueue -> QueueC;
	App.TemperatureSensor -> TemperatureSensorC;
	App.RadiationSensor -> RadiationSensorC;
	App.SmokeSensor -> SmokeSensorC;

	RadioC.App -> App;
} 
