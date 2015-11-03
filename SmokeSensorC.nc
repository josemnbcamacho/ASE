module SmokeSensorC {
	provides interface SensorInterface;
}

implementation {
	command uint16_t SensorInterface.readValue() {
		return 3;
	}
}
