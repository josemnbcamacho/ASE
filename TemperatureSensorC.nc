
module TemperatureSensorC {
	provides interface SensorInterface;
}

implementation {
	command uint16_t SensorInterface.readValue() {
		char val[5];
		FILE* f = fopen("temp", "r");
		fscanf(f, "%s", &val);
		fclose(f);
		return (uint16_t)atoi(val);
	}
}
