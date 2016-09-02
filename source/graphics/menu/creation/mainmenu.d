module mahjong.graphics.menu.creation.mainmenu;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain.enums.game;
import mahjong.engine.gamefront;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.placeholdercontroller;
import mahjong.graphics.controllers.game.singleplayercontroller;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;;
import mahjong.graphics.menu.mainmenu;
import mahjong.graphics.menu.menuitem;
import mahjong.graphics.opts;

private MainMenu _mainMenu;
MainMenu composeMainMenu()
{
	if(_mainMenu !is null) return _mainMenu;
	info("Composing main menu");
	_mainMenu = new MainMenu("Main Menu");
	auto screen = styleOpts.screenSize;
	with(_mainMenu)
	{
		addOption(new MainMenuItem("Riichi Mahjong", 
				&startRiichiMahjong, riichiFile, IntRect(314,0,2*screen.x,2*screen.y)));
		addOption(new MainMenuItem("Bamboo Battle", 
				&startBambooBattle, bambooFile, IntRect(314,0,4*screen.x,4*screen.y)));
		addOption(new MainMenuItem("Thunder Thrill", 
				&startThunderThrill, eightPlayerFile, IntRect(100,0,768,768)));
		addOption(new MainMenuItem("Simple Mahjong", 
				&startSimpleMahjong, chineseFile, IntRect(314,0,2*screen.x,2*screen.y)));
		addOption(new MainMenuItem("Quit", 
				&quit, quitFile, IntRect(150,0,700,700)));
	}
	trace("Constructed all options.");
	_mainMenu.configureGeometry;
	info("Composed main menu;");
	return _mainMenu;
}

private void startRiichiMahjong()
{
	info("Riichi mahjong selected");
	drawingOpts = new DefaultDrawingOpts;
	startGame(GameMode.Riichi);
}

private void startBambooBattle()
{
	info("Bamboo battle selected");
	drawingOpts = new BambooDrawingOpts;
	startGame(GameMode.Bamboo);
}

private void startGame(GameMode gameMode)
{
	//auto console = ConsoleFront.boot;
	//auto gameFronts = console.setUp(gameMode);
	//controller = new SinglePlayerController(controller.getWindow, gameFronts);
	trace("Swapped controller");
}

private void startThunderThrill()
{
	info("Thunder thrill selected");
	controller.roundUp();
	info("Opening placeholder screen");
	controller = new PlaceholderController(controller.getWindow, 
		"Coming soon.", eightPlayerChaos, IntRect(400, 0, 1050, 650));
	trace("Swapped controller");
}

private void startSimpleMahjong()
{
	info("Simple mahjong selected");
	controller.roundUp();
	info("Opening placeholder screen");
	controller = new PlaceholderController(controller.getWindow, 
		"Coming soon.", chineseBg, IntRect(0, 0, 900, 1000));
	trace("Swapped controller");
}

private void quit()
{
	info("Quit selected");
	controller.getWindow.close;
}



