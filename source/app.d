module main;

import dsfml.graphics;
import std.experimental.logger;
import etc.linux.memoryerror;
import mahjong.graphics.cache.font;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;
import mahjong.graphics.ui;


void main(string[] args)
{
	static if (is(typeof(registerMemoryErrorHandler)))
		registerMemoryErrorHandler(); 
	info("Starting mahjong application.");
	
	// Load different fonts so that we do not need to load them every screen.. 
	fontReg = new Font;
	fontBold = new Font;
	fontIt = new Font;
	fontKanji = new Font;

	load(fontReg,fontRegfile);
	load(fontBold,fontBoldfile);
	load(fontIt,fontItfile);
	load(fontKanji, fontKanjifile);


	run;
	info("Mahjong exited normally.");
}
