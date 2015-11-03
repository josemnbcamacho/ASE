module RadiationSensorC {
	provides interface SensorInterface;
}

implementation {
	command uint16_t SensorInterface.readValue() {
		return 1;
	}
}
