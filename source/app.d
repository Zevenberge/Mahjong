module main;

import dsfml.graphics;
import std.experimental.logger;
import etc.linux.memoryerror;
import mahjong.graphics.ui;


void main(string[] args)
{
	static if (is(typeof(registerMemoryErrorHandler)))
		registerMemoryErrorHandler(); 
	info("Starting mahjong application.");
	
	run;
	info("Mahjong exited normally.");
}
