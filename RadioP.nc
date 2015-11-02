generic module RadioP()
{
	provides interface RadioInterface;
	uses {
		interface AMSend;
		interface Receive;
		interface Packet;
		interface AMPacket;
		interface SplitControl as AMControl;
	}
}

implementation
{
	message_t packet;
	bool locked = FALSE;
	am_addr_t parentaddr = 0x0000;
	uint16_t nhops = 0;

	command error_t RadioInterface.sendDiffuse(uint16_t tMeasure) {
		if (locked) {
			return EBUSY;
		}
		else {
			DiffuseMessage* dm = (DiffuseMessage*)call Packet.getPayload(&packet, sizeof(DiffuseMessage));
			if (dm == NULL) {
				return ENOMEM;
			}

			dm->tMeasure = tMeasure;
			dm->messageType = 1;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(DiffuseMessage)) == SUCCESS) {
				dbg("Radio", "RadioP: diffuse message sent. tMeasure=%hu\n", tMeasure);	
				locked = TRUE;
				return SUCCESS;
			}
		}
	}

	command error_t RadioInterface.sendData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke) {
		if (parentaddr == 0x0000) {
			return FAIL;
		}
		if (locked) {
			return EBUSY;
		}
		else {
			CollectMessage* cm = (CollectMessage*)call Packet.getPayload(&packet, sizeof(CollectMessage));
			if (cm == NULL) {
				return ENOMEM;
			}

			cm->nodeid = nodeid;
			cm->radiation = radiation;
			cm->temperature = temperature;
			cm->smoke = smoke;
			if (call AMSend.send(parentaddr, &packet, sizeof(CollectMessage)) == SUCCESS) {
				dbg("Radio", "RadioP: collect message, nodeid=%hu, r=%hu, t=%hu, s=%hu\n", nodeid, radiation, temperature, smoke);	
				locked = TRUE;
				return SUCCESS;
			}
		}
	}

	command error_t RadioInterface.sendJoin() {
		if (parentaddr == 0x0000) {
			return FAIL;
		}
		if (locked) {
			return EBUSY;
		}
		else {
			JoinMessage* jm = (JoinMessage*)call Packet.getPayload(&packet, sizeof(JoinMessage));
			if (jm == NULL) {
				return ENOMEM;
			}

			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(JoinMessage)) == SUCCESS) {
				dbg("Radio", "RadioP: join message sent.\n");	
				locked = TRUE;
				return SUCCESS;
			}
		}
	}

	event void AMControl.startDone(error_t err) {
	}
	event void AMControl.stopDone(error_t err) {
	}
	event void AMSend.sendDone(message_t* msg, error_t error) {
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(JoinMessage)) {
			if (locked) {
				dbg("Radio", "RadioP: join response message failed\n");
				return msg;
			}
			else {
				JoinResponseMessage* jrm = (JoinResponseMessage*)call Packet.getPayload(&packet, sizeof(JoinResponseMessage));
				if (jrm == NULL) {
					dbg("Radio", "RadioP: join response message failed\n");
					return msg;
				}

				jrm->nhops = nhops;
				jrm->messageType = 0;
				if (call AMSend.send(call AMPacket.address(), &packet, sizeof(JoinResponseMessage)) == SUCCESS) {
					dbg("Radio", "RadioP: join response message, nhops=%hu\n", nhops);	
					locked = TRUE;
					return msg;
				}
			}
		} else if(len == sizeof(JoinResponseMessage)) {
			JoinResponseMessage* jrm = (JoinResponseMessage*)payload;
			if(jrm->messageType == 0) {
				// TODO: Timer collecting join messages
			} else {
				DiffuseMessage* dm = (DiffuseMessage*)payload;
				if(call AMPacket.address() != parentaddr) { 							// if it's not from the parent the message must be ignored
					dbg("RadioDBG", "RadioP: diffuse message is not for this node\n");
					return msg;
				}
				signal RadioInterface.receiveDiffuse(dm->tMeasure);
				// TODO: set timer for failure
				if (locked) {
					dbg("Radio", "RadioP: diffuse message passing failed\n");
					return msg;
				}
				else {
					DiffuseMessage* dmessage = (DiffuseMessage*)call Packet.getPayload(&packet, sizeof(DiffuseMessage));
					if (dmessage == NULL) {
						dbg("Radio", "RadioP: diffuse message passing failed\n");
						return msg;
					}

					memcpy(dmessage, payload, sizeof(DiffuseMessage));
					if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(DiffuseMessage)) == SUCCESS) {
						dbg("Radio", "RadioP: diffuse message passing\n");	
						locked = TRUE;
						return msg;
					}
				}
			}
		} else if (len == sizeof(CollectMessage)) {
			if(TOS_NODE_ID == 0) {
				CollectMessage* cm = (CollectMessage*)payload;
				signal RadioInterface.receiveData(cm->nodeid, cm->radiation, cm->temperature, cm->smoke);
			} else {
				// TODO: Timer for acks and send failures
				if (locked) {
					dbg("Radio", "RadioP: collect message passing failed\n");
					return msg;
				}
				else {
					CollectMessage* cm = (CollectMessage*)call Packet.getPayload(&packet, sizeof(CollectMessage));
					if (cm == NULL) {
						dbg("Radio", "RadioP: collect message passing failed\n");
						return msg;
					}

					memcpy(cm, payload, sizeof(CollectMessage));
					if (call AMSend.send(parentaddr, &packet, sizeof(CollectMessage)) == SUCCESS) {
						dbg("Radio", "RadioP: collect message passing\n");	
						locked = TRUE;
						return msg;
					}
				}
			}
		} else {
			dbg("Radio", "RadioP: unknown packet, len=%hu\n", len);
		}
		return msg;
	}
} 
