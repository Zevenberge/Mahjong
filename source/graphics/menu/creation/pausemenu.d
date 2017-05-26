module mahjong.graphics.menu.creation.pausemenu;

import std.experimental.logger;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu.mainmenucontroller;
import mahjong.graphics.controllers.menu.menucontroller;
import mahjong.graphics.menu;

private Menu _pauseMenu;
Menu composePauseMenu()
{
	if(_pauseMenu !is null) return _pauseMenu;
	info("Composing pause menu");
	_pauseMenu = new Menu("");
	with(_pauseMenu)
	{
		addOption(new MenuItem("Continue", {continueGame;}));
		addOption(new MenuItem("Quit", {quitGame;}));
	}
	trace("Constructed all options.");
	_pauseMenu.configureGeometry;
	info("Composed pause menu");
	return _pauseMenu;
}

private void continueGame()
{
	trace("Continuing game");
	auto menuController = cast(MenuController)controller;
	if(menuController !is null)
	{
		menuController.closeMenu;
	}
	trace("Closed menu");
}

private void quitGame()
{
	trace("Quitting game");
	controller.roundUp;
	auto mainMenuController = getMainMenuController(controller.getWindow);
	controller = mainMenuController;
	trace("Returned to the main menu");
}

