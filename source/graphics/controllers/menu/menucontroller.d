module mahjong.graphics.controllers.menu.menucontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.opts;

class MenuController : MenuControllerBase!Menu
{
	this(RenderWindow window, Controller pausedController, Menu menu)
	{
		trace("Creating menu controller");
		super(window, menu);
		_innerController = pausedController;
		_haze = new RectangleShape(styleOpts.screenSize.toVector2f);
		_haze.fillColor = Color(126,126,126,126);
	}
	
	override void draw()
	{
		_innerController.draw;
		_window.draw(_haze);
		_menu.draw(_window);
	}
	
	protected override bool menuClosed()
	{
		closeMenu;
		return false;
	}
	
	void closeMenu()
	{
		controller = _innerController;
	}
	
	private:
		Controller _innerController;
		RectangleShape _haze;
}