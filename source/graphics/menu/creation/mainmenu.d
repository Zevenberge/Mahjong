module mahjong.graphics.menu.creation.mainmenu;

import std.experimental.logger;
import std.functional;
import dsfml.graphics;
import mahjong.domain.enums;
import mahjong.engine.ai;
import mahjong.engine.flow;
import mahjong.engine.opts;
import mahjong.graphics.controllers;
import mahjong.graphics.controllers.placeholdercontroller;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.eventhandler;
import mahjong.graphics.menu;
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
				(&startRiichiMahjong).toDelegate, riichiFile, IntRect(314,0,2*screen.x,2*screen.y)));
		addOption(new MainMenuItem("Bamboo Battle", 
				(&startBambooBattle).toDelegate, bambooFile, IntRect(314,0,4*screen.x,4*screen.y)));
		addOption(new MainMenuItem("Thunder Thrill", 
				(&startThunderThrill).toDelegate, eightPlayerFile, IntRect(100,0,768,768)));
		addOption(new MainMenuItem("Simple Mahjong", 
				(&startSimpleMahjong).toDelegate, chineseFile, IntRect(314,0,2*screen.x,2*screen.y)));
		addOption(new MainMenuItem("Quit", 
				(&quit).toDelegate, quitFile, IntRect(150,0,700,700)));
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
	gameOpts = new DefaultGameOpts;
	startGame(
		new UiEventHandler, 
		new AiEventHandler(new SimpleAI), 
		new AiEventHandler(new SimpleAI), 
		new AiEventHandler(new SimpleAI));
}
///
unittest
{
	import std.stdio;
	import mahjong.engine.opts;
	import mahjong.test.utils;
	writeln("Testing the start of the normal mahjong.");
	setDefaultTestController;
	startRiichiMahjong;
	assert(controller.isOfType!IdleController, 
		"The controller should be instantiated");
	assert(drawingOpts.isOfType!DefaultDrawingOpts, 
		"For simple riichi mahjong, the drawing options should be the default");
	assert(gameOpts.isOfType!DefaultGameOpts,
		"For simple riichi mahjong, the game options should be the default");
	writeln("Test of the start of the normal mahjong succeeded.");
}

private void startBambooBattle()
{
	info("Bamboo battle selected");
	drawingOpts = new BambooDrawingOpts;
	gameOpts = new BambooOpts;
	startGame(
		new UiEventHandler, 
		new AiEventHandler(new SimpleAI));
}
///
unittest
{
	import std.stdio;
	import mahjong.engine.opts;
	import mahjong.test.utils;
	writeln("Testing the start of the bamboo mahjong.");
	setDefaultTestController;
	startBambooBattle;
	assert(controller.isOfType!IdleController, 
		"The controller should be instantiated");
	assert(drawingOpts.isOfType!BambooDrawingOpts, 
		"For bamboo riichi mahjong, the drawing options should be specific");
	assert(gameOpts.isOfType!BambooOpts,
		"For bamboo riichi mahjong, the game options should be specific");
	writeln("Test of the start of the normal mahjong succeeded.");
}

private void startGame(GameEventHandler[] eventHandlers...)
{
	switchFlow(new GameStartFlow(eventHandlers));
	trace("Initiated Game Start Flow");
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



