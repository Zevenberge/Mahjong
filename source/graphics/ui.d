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
	window.setFramerateLimit(60);
	
	trace("Creating initial controller");
	controller = getMainMenuController(window);
	trace("Starting application loop");
	try
	{
		windowLoop: while(window.isOpen)
		{
			Event event;
			while(window.pollEvent(event))
			{
				if(controller.handleEvent(event))
				{
					info("Exiting ", controller.classinfo);
					window.close;
					break windowLoop;
				}
			}
			controller.draw;
			window.display;
			controller.animate;
			controller.yield;
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
	if(controller !is null)
	{
		controller.roundUp;
	}
}