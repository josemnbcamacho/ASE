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
		interface Queue<MessageData> as OutQueue;
		interface Queue<MessageData> as PriorityQueue;
		interface Timer<TMilli> as MilliTimer;

		interface NuclearPlantInterface as NuclearPlant;
	}
}

implementation
{
	message_t packet;
	bool sendLocked = FALSE;
	am_addr_t parentaddr = AM_BROADCAST_ADDR;
	uint16_t nhops = 0;
	uint8_t diffid = 0;

	bool collectingJoins = FALSE;
	uint8_t awaitingACK = 0;

	am_addr_t pendingACK = AM_BROADCAST_ADDR;

	command void RadioInterface.startRadio() {
		call AMControl.start();
	}

	command error_t RadioInterface.sendDiffuse(uint16_t tMeasure) {
		DiffuseMessage dm;
		dm.tMeasure = tMeasure;
		dm.diffid = diffid + 1;

		dbg("Radio", "RadioP: queueing diffuse message, tMeasure=%hu\n", tMeasure);	
		return call RadioInterface.sendMessage(AM_BROADCAST_ADDR, (void*)&dm, sizeof(DiffuseMessage));
	}

	command error_t RadioInterface.sendData(uint16_t nodeid, uint16_t radiation, uint16_t temperature, uint16_t smoke) {
		CollectMessage cm;
		if (parentaddr == AM_BROADCAST_ADDR) {
			return FAIL;
		}

		cm.nodeid = nodeid;
		cm.radiation = radiation;
		cm.temperature = temperature;
		cm.smoke = smoke;

		dbg("Radio", "RadioP: queueing collect message, nodeid=%hu, r=%hu, t=%hu, s=%hu\n", nodeid, radiation, temperature, smoke);	
		return call RadioInterface.sendMessage(parentaddr, (void*)&cm, sizeof(CollectMessage));
	}

	command error_t RadioInterface.sendJoin() {
		JoinMessage jm;

		jm.messageType = 1;
		dbg("Radio", "RadioP: queueing join message\n");	
		return call RadioInterface.sendMessage(AM_BROADCAST_ADDR, (void*)&jm, sizeof(JoinMessage));
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
			sendLocked = FALSE;
			dbg("RadioDebug", "RadioP: sendDone\n");
			
			if ((call Packet.payloadLength(msg)) == sizeof(CollectMessage)) { // we sent a collect packet
				awaitingACK = awaitingACK + 1;
				if (awaitingACK == 1)
					call MilliTimer.startOneShot(TIME_FAILURE_ACK); // start failure timer
				signal RadioInterface.sendDataDone();
			}
			
			if (call PriorityQueue.size() > 0)
				call RadioInterface.dispatch(call PriorityQueue.dequeue());
			else if (call OutQueue.size() > 0 && awaitingACK == 0) {
				call RadioInterface.dispatch(call OutQueue.dequeue());
			} 
		} else {
			dbg("RadioDebug", "RadioP: something wierd happened\n");
		}
	}

	command void RadioInterface.sendACK(am_addr_t dest) {
		AckMessage ack;
		ack.messageType = 0;
		dbg("Radio", "RadioP: queueing ack message\n");	
		call RadioInterface.sendMessage(dest, (void*)&ack, sizeof(AckMessage));
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
			nhops = bestCandidate.nhops + 1;
			dbg("RadioDebug", "RadioP: decided parent\n");
			call NuclearPlant.setTMeasure(bestCandidate.tMeasure);
			call NuclearPlant.startCollect();
		} else if (awaitingACK) {
			dbg("RadioDebug", "RadioP: failed to receive ack\n");
			awaitingACK = awaitingACK - 1;
			if (awaitingACK > 0)
					call MilliTimer.startOneShot(TIME_FAILURE_ACK);
			call NuclearPlant.haltSendData();
			call RadioInterface.sendJoin();
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		dbg("RadioDebug", "RadioP: received, len=%hu\n", len);
		if (len == sizeof(JoinMessage)) {
			JoinMessage* jm = (JoinMessage*) payload;
			if (jm->messageType == 1) { // its an JoinMessage
				JoinResponseMessage jrm;
				jrm.nhops = nhops;
				jrm.diffid = diffid;
				jrm.tMeasure = call NuclearPlant.getTMeasure();

				// TODO: test or ignore failure..
				dbg("Radio", "RadioP: queueing join response message, nhops=%hu\n", nhops);
				call RadioInterface.sendMessage(call AMPacket.source(msg), (void*)&jrm, sizeof(JoinResponseMessage));
			} else { // its an Ack
				dbg("RadioDebug", "RadioP: received ack, %hu\n", awaitingACK);
				awaitingACK = awaitingACK - 1;
				call MilliTimer.stop();
				if (awaitingACK > 0)
					call MilliTimer.startOneShot(TIME_FAILURE_ACK);
				
				if (call PriorityQueue.size() > 0 && !sendLocked) {
					call RadioInterface.dispatch(call PriorityQueue.dequeue());
				} else if (call OutQueue.size() > 0 && !sendLocked) {
					call RadioInterface.dispatch(call OutQueue.dequeue());
				}
			}
		} else if (len == sizeof(JoinResponseMessage)) {
			JoinResponseMessage* jrm = (JoinResponseMessage*) payload;
			
			dbg("RadioDebug", "RadioP: received join response message\n");
			if (!collectingJoins) {
				collectingJoins = TRUE;
				call MilliTimer.startOneShot(TIMER_JOIN_COLLECT);
			}

			if (call Queue.size() < call Queue.maxSize()) {
				ParentCandidate parent;
				parent.addr = call AMPacket.source(msg);
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

				// TODO: test or ignore failure..
				dbg("Radio", "RadioP: queueing diffuse message passing\n");
				call RadioInterface.sendMessage(AM_BROADCAST_ADDR, payload, sizeof(DiffuseMessage));
			} else {
				dbg("RadioDebug", "RadioP: diffuse message out of order, diffid=%hu, msgdiffid=%hu\n", diffid, dm->diffid);
				return msg;
			}
		} else if (len == sizeof(CollectMessage)) {
			CollectMessage* cm = (CollectMessage*)payload;
			if (cm->nodeid == TOS_NODE_ID) {
				call NuclearPlant.haltSendData();
				call RadioInterface.sendJoin();
				return msg;
			}
			
			if (TOS_NODE_ID == 0) {
				signal RadioInterface.receiveData(cm->nodeid, cm->radiation, cm->temperature, cm->smoke);
				dbg("RadioDebug", "RadioP: queueing root ack for collection\n");
				call RadioInterface.sendACK(call AMPacket.source(msg));
			} else {

				// TODO: test or ignore failure..
				dbg("Radio", "RadioP: queueing collect message passing\n");
				call RadioInterface.sendMessage(parentaddr, payload, sizeof(CollectMessage));
				call RadioInterface.sendACK(call AMPacket.source(msg));
			}
		} else {
			dbg("Radio", "RadioP: unknown packet, len=%hu\n", len);
		}
		return msg;
	}
	command error_t RadioInterface.sendMessage(am_addr_t destination, void* data, uint8_t len) {
		MessageData msg;
		bool priority = (len == sizeof(AckMessage) && ((AckMessage*)data)->messageType == 0);
		if (priority) {
			if ((call PriorityQueue.size() == call PriorityQueue.maxSize()) && sendLocked) {
				dbg("Radio", "RadioP: priority queue is full, discarded\n");
				return FAIL;
			}
		} else {
			if ((call OutQueue.size() == call OutQueue.maxSize()) && sendLocked) {
				dbg("Radio", "RadioP: message queue is full, discarded\n");
				return FAIL;
			}
		}

		msg.len = len;
		msg.addr = destination;
		memcpy(msg.data, data, len);

		if (sendLocked) {
			if (priority)
				call PriorityQueue.enqueue(msg);
			else
				call OutQueue.enqueue(msg);
		} else {
			if (!priority && awaitingACK > 0)
				call OutQueue.enqueue(msg);
			else
				call RadioInterface.dispatch(msg);
		}
		return SUCCESS;
	}
	
	command void RadioInterface.dispatch(MessageData msg) {
		void* payload = call Packet.getPayload(&packet, sizeof(CollectMessage));
		if (payload == NULL) {
			dbg("Radio", "RadioP: error allocating payload, len=%hu", msg.len);
			return;
		}
		
		memcpy(payload, msg.data, msg.len);
		if (call AMSend.send(msg.addr, &packet, msg.len) == SUCCESS) {
			dbg("Radio", "RadioP: message dispatched, len=%hu\n", msg.len);	
			sendLocked = TRUE;
		} else {
			dbg("Radio", "RadioP: message dispatch failed, len=%hu\n", msg.len);	
		}
	}
} 
