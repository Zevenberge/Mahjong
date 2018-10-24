module mahjong.graphics.controllers.menu.mainmenucontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.menu.mainmenu;

class MainMenuController : MenuControllerBase!MainMenu
{
	this(RenderWindow window, MainMenu mainMenu)
	{
		trace("Creating Main Menu controller");
		super(window, mainMenu);
	}

    void showMenu()
    {
        info("Showing main menu");
        instance = this;
    }
	
	protected override bool menuClosed()
	{
		return true;
	}
}

MainMenuController getMainMenuController(RenderWindow window)
{
	trace("Creating main menu");
	auto mainMenu = getMainMenu;
	return new MainMenuController(window, mainMenu);
}


