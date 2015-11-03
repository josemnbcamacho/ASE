interface NuclearPlantInterface {
	command void startCollect();
	command void haltSendData();
	command uint16_t getTMeasure();
	command void setTMeasure(uint16_t tMeasure);
} 
