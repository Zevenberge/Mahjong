module mahjong.graphics.ui;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu.mainmenucontroller;
import mahjong.graphics.menu.mainmenu;
import mahjong.graphics.opts.defaultopts;
import mahjong.graphics.opts.opts;

void run()
{
	trace("Setting drawing options");
	drawingOpts = new DefaultDrawingOpts;
	trace("Creating window.");
	auto window = new RenderWindow(VideoMode(drawingOpts.screenSize.x, 
							drawingOpts.screenSize.y), drawingOpts.screenHeader);
	window.setFramerateLimit(60);
	trace("Creating main menu");
	auto mainMenu = getMainMenu;
	trace("Creating initial controller");
	controller = new MainMenuController(window, mainMenu);
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