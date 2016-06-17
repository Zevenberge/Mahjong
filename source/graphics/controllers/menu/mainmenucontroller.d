module mahjong.graphics.controllers.menu.mainmenucontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu.menucontrollerbase;
import mahjong.graphics.menu.mainmenu;

class MainMenuController : MenuControllerBase!MainMenu
{
	this(RenderWindow window, MainMenu mainMenu)
	{
		trace("Creating Main Menu controller");
		super(window, mainMenu);
	}
	
	protected override bool menuClosed()
	{
		return true;
	}
		
}



