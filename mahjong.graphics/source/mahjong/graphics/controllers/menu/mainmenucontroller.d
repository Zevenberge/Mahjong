module mahjong.graphics.controllers.menu.mainmenucontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.menu.mainmenu;

class MainMenuController : MenuControllerBase!MainMenu
{
	this(MainMenu mainMenu)
	{
		trace("Creating Main Menu controller");
		super(mainMenu);
	}

	protected override bool menuClosed()
	{
		return true;
	}
}