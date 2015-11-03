generic module RadioP()
{
	provides interface RadioInterface;
	uses {
		interface AMSend;
		interface Receive;
		interface Packet;
		interface AMPacket;
		interface SplitControl as AMControl;
		interface Queue<ParentCandidate>;
		interface Timer<TMilli> as MilliTimer;

		interface NuclearPlantInterface as NuclearPlant;
	}
}

implementation
{
	message_t packet;
	bool locked = FALSE;
	am_addr_t parentaddr = 0x0000;
	uint16_t nhops = 0;
	uint8_t diffid = 0;

	bool collectingJoins = FALSE;
	bool awaitingACK = FALSE;

	am_addr_t pendingACK = 0x0000;

	command void RadioInterface.startRadio() {
		call AMControl.start();
	}

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
			dm->diffid = diffid + 1;
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
		return FAIL;
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
		return FAIL;
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			if (TOS_NODE_ID != 0) {
				call RadioInterface.sendJoin();
			} else {
				call NuclearPlant.startCollect();
			}
			dbg("Radio", "RadioP started\n");	
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
		// do nothing
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (msg ==  &packet) {
			locked = FALSE;
			if ((call Packet.payloadLength(msg)) == sizeof(CollectMessage)) { // we sent a collect packet
				signal RadioInterface.sendDataDone();
			}

			if (pendingACK != 0x0000) {
				AckMessage* ack = (AckMessage*)call Packet.getPayload(&packet, sizeof(AckMessage));
				if (ack == NULL) {
					dbg("RadioDebug", "RadioP: sending ack failed\n");
				}

				ack->messageType = 0;
				if (call AMSend.send(pendingACK, &packet, sizeof(AckMessage)) == SUCCESS) {
					dbg("RadioDebug", "RadioP: sending ack\n");	
					locked = TRUE;
					pendingACK = 0x0000;
				} else {
					dbg("RadioDebug", "RadioP: sending ack, AMSend failed\n");
				}
			}
		}
	}

	event void MilliTimer.fired() {
		if (collectingJoins) {
			ParentCandidate bestCandidate;
			collectingJoins = FALSE;
			bestCandidate.nhops = MAX_NHOPS;
			while (!(call Queue.empty())) {
				ParentCandidate head = call Queue.dequeue();
				if (head.nhops < bestCandidate.nhops)
					bestCandidate = head;
			}
			parentaddr = bestCandidate.addr;
			nhops = bestCandidate.nhops;
			call NuclearPlant.setTMeasure(bestCandidate.tMeasure);
			call NuclearPlant.startCollect();
		} else if (awaitingACK) {
			awaitingACK = FALSE;
			call NuclearPlant.haltSendData();
			call RadioInterface.sendJoin();
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(JoinMessage)) {
			JoinMessage* jm = (JoinMessage*) payload;
			if (jm->messageType == 1) { // its an JoinMessage
				// TODO: Timer to resend message
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
					jrm->diffid = diffid;
					jrm->tMeasure = call NuclearPlant.getTMeasure();
					if (call AMSend.send(call AMPacket.address(), &packet, sizeof(JoinResponseMessage)) == SUCCESS) {
						dbg("Radio", "RadioP: join response message, nhops=%hu\n", nhops);	
						locked = TRUE;
						return msg;
					}
				}
			} else { // its an Ack
				call MilliTimer.stop();
			}
		} else if (len == sizeof(JoinResponseMessage)) {
			JoinResponseMessage* jrm = (JoinResponseMessage*) payload;
			
			if (!collectingJoins) {
				collectingJoins = TRUE;
				call MilliTimer.startOneShot(TIMER_JOIN_COLLECT);
			}

			if (call Queue.size() < call Queue.maxSize()) {
				ParentCandidate parent;
				parent.addr = call AMPacket.address();
				parent.nhops = jrm->nhops;
				parent.tMeasure = jrm->tMeasure;
				call Queue.enqueue(parent);
			}
		} else if (len == sizeof(DiffuseMessage)) {
			DiffuseMessage* dm = (DiffuseMessage*) payload;
			if ((diffid > 245 && (dm->diffid > diffid || dm->diffid < 10))
					|| (dm->diffid > diffid && dm->diffid < diffid+10)) {
				diffid = dm->diffid;
				signal RadioInterface.receiveDiffuse(dm->tMeasure);
				// TODO: Timer to resend message
				if (locked) {
					dbg("Radio", "RadioP: diffuse message passing failed\n");
					return msg;
				} else {
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
			} else {
				dbg("RadioDebug", "RadioP: diffuse message out of order, diffid=%hu, msgdiffid=%hu\n", diffid, dm->diffid);
				return msg;
			}
		} else if (len == sizeof(CollectMessage)) {
			if (TOS_NODE_ID == 0) {
				CollectMessage* cm = (CollectMessage*)payload;
				signal RadioInterface.receiveData(cm->nodeid, cm->radiation, cm->temperature, cm->smoke);
			} else {
				awaitingACK = TRUE;
				call MilliTimer.startOneShot(TIME_FAILURE_ACK); // start failure timer
				// TODO: Timer to resend message
				if (locked) {
					dbg("Radio", "RadioP: collect message passing failed\n");
					return msg;
				}
				else {
					am_addr_t pendingACKAddr = call AMPacket.address();
					CollectMessage* cm = (CollectMessage*)call Packet.getPayload(&packet, sizeof(CollectMessage));
					if (cm == NULL) {
						dbg("Radio", "RadioP: collect message passing failed\n");
						return msg;
					}
					
					memcpy(cm, payload, sizeof(CollectMessage));
					if (call AMSend.send(parentaddr, &packet, sizeof(CollectMessage)) == SUCCESS) {
						dbg("Radio", "RadioP: collect message passing\n");	
						locked = TRUE;
						pendingACK = pendingACKAddr;
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
