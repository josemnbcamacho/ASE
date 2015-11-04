#!/usr/bin/env python

from TOSSIM import *
import cmd

'''
class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""
	def do_greet(self, person):
		if person:
			print "hi,", person
		else:
			print 'hi'
	
	def help_greet(self):
		print '\n'.join([ 'greet [person]', 'Greet the named person',])
	
	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	HelloWorld().cmdloop()
	t = Tossim([])
'''

import sys
t = Tossim([])
t.addChannel("Boot", sys.stdout)
t.addChannel("Collection", sys.stdout)
t.addChannel("CollectionDebug", sys.stdout)
t.addChannel("Receive", sys.stdout)
t.addChannel("Radio", sys.stdout)
t.addChannel("RadioDebug", sys.stdout)

r = t.radio()
f = open("topo.txt", "r")

for line in f:
  s = line.split()
  if s:
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

noise = open("//opt/tinyos/tos/lib/tossim/noise/meyer-heavy.txt", "r")
for line in noise:
  str1 = line.strip()
  if str1:
    val = int(str1)
    for i in range(0, 3):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(0, 3):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()
  

t.getNode(0).bootAtTime(100001);
t.getNode(1).bootAtTime(8000000008);
t.getNode(2).bootAtTime(48000000009);

for i in range(10000):
  t.runNextEvent()