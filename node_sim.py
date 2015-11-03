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
t.addChannel("Receive", sys.stdout)
t.addChannel("Radio", sys.stdout)
t.addChannel("RadioDebug", sys.stdout)
server = t.getNode(0)
server.bootAtTime(0)

t.runNextEvent()