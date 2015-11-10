module RadiationSensorC {
	provides interface SensorInterface;
}

implementation {
	command uint16_t SensorInterface.readValue() {
		char val[5];
		char filename[255];
		FILE* f;
		sprintf(filename, "sensors/radiation/%hu", TOS_NODE_ID);
		f = fopen(filename, "r");
		if (f == NULL)
			return 65535;
		fscanf(f, "%s", &val);
		fclose(f);
		return (uint16_t)atoi(val);
	}
}
