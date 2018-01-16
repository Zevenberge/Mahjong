module mahjong.graphics.controllers.menu.menucontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.opts;

class MenuController : MenuControllerBase!Menu, ISubstrituteInnerController
{
	this(RenderWindow window, Controller pausedController, Menu menu)
	{
		trace("Creating menu controller");
		super(window, menu);
		_innerController = pausedController;
		_haze = constructHaze;
	}
	
	override void draw()
	{
		_innerController.draw;
		_window.draw(_haze);
		_menu.draw(_window);
	}

	override void roundUp() 
	{
		super.roundUp;
		_innerController.roundUp;
	}
	
	protected override bool menuClosed()
	{
		closeMenu;
		return false;
	}
	
	void closeMenu()
	{
		switchController(_innerController);
	}

	void substitute(Controller newController)
	{
		_innerController = newController;
	}

	protected RectangleShape constructHaze()
	{
		auto haze = new RectangleShape(styleOpts.screenSize.toVector2f);
		haze.fillColor = styleOpts.menuHazeColor;
		return haze;
	}

	protected Controller _innerController;
	private RectangleShape _haze;
}