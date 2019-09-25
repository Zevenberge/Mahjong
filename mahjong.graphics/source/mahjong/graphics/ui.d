module mahjong.graphics.ui;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.mainmenu;
import mahjong.graphics.menu.creation.mainmenu;
import mahjong.graphics.opts;
import mahjong.util.log;

void run()
{
	trace("Setting drawing options");
	styleOpts = new DefaultStyleOpts;
	trace("Creating window.");
	auto window = new RenderWindow(VideoMode(styleOpts.screenSize.x, 
					styleOpts.screenSize.y), styleOpts.screenHeader);
	import mahjong.graphics.parallelism;
	auto worker = new BackgroundWorker(window);
	scope(exit) worker.stop;
	window.setFramerateLimit(60);
	
	trace("Creating initial controller");
    auto mainMenuController = new MainMenuController(composeMainMenu(window, worker));
	Controller.instance.substitute(mainMenuController);
	trace("Starting application loop");
	try
	{
		windowLoop: while(window.isOpen)
		{
			worker.poll();
			Event event;
			while(window.pollEvent(event))
			{
				if(Controller.instance.handleEvent(event))
				{
					info("Exiting ", Controller.instance);
					window.close;
					break windowLoop;
				}
			}
			trace("MAIN LOOP DRAWING START");
			Controller.instance.draw(window);
			trace("MAIN LOOP DRAWING END");
			trace("MAIN LOOP DISPLAY START");
			window.display;
			trace("MAIN LOOP DISPLAY END");
			trace("MAIN LOOP ANIMATE START");
			Controller.instance.animate;
			trace("MAIN LOOP ANIMATE END");
			trace("MAIN LOOP YIELD START");
			Controller.instance.yield;
			trace("MAIN LOOP YIELD END");
		}
	}
	catch(Exception e)
	{
		error("Application exception");
		writeThrowable(e);
		throw e;
	}
	catch(Error e)
	{
		critical("Application error");
		writeThrowable(e);
		throw e;
	}
}