module mahjong.graphics.ui;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu.mainmenucontroller;
import mahjong.graphics.opts;

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
    auto mainMenuController = getMainMenuController(window, worker);
    mainMenuController.showMenu;
	trace("Starting application loop");
	try
	{
		windowLoop: while(window.isOpen)
		{
			import std.stdio;
			worker.poll((int _) {writeln("Received ", _);});
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
			Controller.instance.draw;
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

private void writeThrowable(Throwable t)
{
	while(t !is null)
	{
		error(t.msg, "\n", t.file, " at ", t.line	);
		error("Stacktrace: \n", t.info);
		t = t.next;
	}
}

static ~this()
{
	if(Controller.instance !is null)
	{
		Controller.instance.roundUp;
	}
}