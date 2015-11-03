module TemperatureSensorC {
	provides interface SensorInterface;
}

implementation {
	command uint16_t SensorInterface.readValue() {
		return 2;
	}
}
