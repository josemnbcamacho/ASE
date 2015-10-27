#include <Timer.h>
#include "NuclearPlant.h"

configuration NuclearPlantAppC {
}
implementation {
	components MainC;
	components NuclearPlantC as App;
	components new TimerMilliC() as Timer0;
	components new RadioC(AM_PLANTRADIO);


	App.Boot -> MainC;
	App.RadioInterface -> RadioC;
	App.Timer0 -> Timer0;
} 
