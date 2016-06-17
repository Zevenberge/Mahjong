module mahjong.graphics.controllers.menu.menucontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu.menucontrollerbase;
import mahjong.graphics.menu.menu;

class MenuController : MenuControllerBase!Menu
{
	this(RenderWindow window, Controller pausedController, Menu menu)
	{
		trace("Creating menu controller");
		super(window, menu);
		_innerController = pausedController;
	}
	
	override void draw()
	{
		_innerController.draw;
	}
	
	protected override bool menuClosed()
	{
		return false;
	}
	
	private:
		Controller _innerController;
		Menu _menu;
}