module mahjong.graphics.controllers.menu.mainmenucontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.menu.mainmenu;

class MainMenuController : Controller
{
	this(MainMenu mainMenu)
	{
		trace("Creating Main Menu controller");
		_menu = mainMenu;
	}

	private MainMenu _menu;

	override void draw(RenderTarget target)
	{
		target.clear;
		_menu.draw(target);
	}
	
	override bool handleKeyEvent(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Up:
				_menu.selectPrevious;
				break;
			case Down:
				_menu.selectNext;
				break;
			case Return:
				_menu.selectedItem.select;
				break;
			case Escape:
				return true;
			default:
		}
		return false;
	}
	
	override void roundUp() {}
	
	override void yield() {}
}