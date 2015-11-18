#!/usr/bin/env python

from TOSSIM import *
from tinyos.tossim.TossimApp import *
from DiffuseMessage import *
import cmd
import sys


class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""
	def do_run(self, number):
		if number == '':
			number = 1
		for i in range(int(number)):
			t.runNextEvent()
	
	def help_run(self):
		print '\n'.join([ 'run [number]', 'Runs a number of events',])
		
	def do_stopnode(self, id):
		t.getNode(int(id)).turnOff()
		print 'Node turned off'
		
	def help_stopnode(self):
		print '\n'.join([ 'stopnode <id>', 'Stop a node with a given id',])
		
	def do_newtmeasure(self, tMeasure):
		currentDiffID = int(t.getNode(0).getVariable("RadioP.diffid").getData())
		msg = DiffuseMessage()
		msg.set_tMeasure(int(tMeasure))
		msg.set_diffid(1)
		pkt = t.newPacket()
		pkt.setData(msg.data)
		pkt.setType(msg.get_amType())
		pkt.setDestination(0)
		pkt.deliverNow(0)
		print 'New tMeasure defined'
		
	def help_newtmeasure(self):
		print '\n'.join([ 'newtmeasure <tMeasure>', 'Sends a new tMeasure to the network',])
		
	def do_failsensor(self, line):
		[id, sensor] = line.split(' ')
		with open('sensors/' + sensor + '/' + id, 'w') as sensorfile:
			sensorfile.write('65535\n');
		
	def help_failsensor(self):
		print '\n'.join([ 'failsensor <id> <radiation|temperature|smoke>', 'Makes a sensor fail',])
			
	def do_setsensor(self, line):
		[id, sensor, value] = line.split(' ')
		with open('sensors/' + sensor + '/' + id, 'w') as sensorfile:
			sensorfile.write(value + '\n');
		
	def help_setsensor(self):
		print '\n'.join([ 'setsensor <id> <radiation|temperature|smoke> <value>', 'Sets a value for a sensor',])
		
	def do_EOF(self, line):
		return True

n = NescApp("Unknown App", "app.xml")
t = Tossim(n.variables.variables())
t.addChannel("Boot", sys.stdout)
t.addChannel("Collection", sys.stdout)
t.addChannel("CollectionDebug", sys.stdout)
t.addChannel("Receive", sys.stdout)
t.addChannel("Radio", sys.stdout)
t.addChannel("RadioDebug", sys.stdout)

r = t.radio()
f = open("topo.txt", "r")
max_node = 0
for line in f:
  s = line.split()
  if s:
    print " ", s[0], " ", s[1], " ", s[2];
    max_node = max(max_node, int(s[0]), int(s[1]))
    r.add(int(s[0]), int(s[1]), float(s[2]))

noise = open("meyer-heavy.txt", "r")
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(0, max_node+1):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(0, max_node+1):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

for i in range(0, max_node+1):
	t.getNode(i).bootAtTime(12000000008 * i + 10000);

HelloWorld().cmdloop()
