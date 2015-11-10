COMPONENT=NuclearPlantAppC
BUILD_EXTRA_DEPS = DiffuseMessage.py DiffuseMessage.class

DiffuseMessage.py: RadioMessages.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=DiffuseMessage RadioMessages.h DiffuseMessage -o $@

DiffuseMessage.class: DiffuseMessage.java
	javac DiffuseMessage.java

DiffuseMessage.java: RadioMessages.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=DiffuseMessage RadioMessages.h DiffuseMessage -o $@

include $(MAKERULES)