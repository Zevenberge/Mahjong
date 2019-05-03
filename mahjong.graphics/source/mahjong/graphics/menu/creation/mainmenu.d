module mahjong.graphics.menu.creation.mainmenu;

import std.experimental.logger;
import std.functional;
import dsfml.graphics;
import mahjong.ai;
import mahjong.domain.opts;
import mahjong.domain.enums;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.controllers.placeholdercontroller;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.eventhandler;
import mahjong.graphics.menu;
import mahjong.graphics.opts;
import mahjong.graphics.parallelism;
import mahjong.graphics.popup.service;
alias Opts = mahjong.domain.opts.Opts;
alias DrawingOpts = mahjong.graphics.opts.Opts;

private MainMenu _mainMenu;
MainMenu composeMainMenu(BackgroundWorker bg)
{
	if(_mainMenu !is null) return _mainMenu;
	info("Composing main menu");
	_mainMenu = new MainMenu("Main Menu");
	auto screen = styleOpts.screenSize;
	with(_mainMenu)
	{
		addOption(new MainMenuItem("Riichi Mahjong", 
				() => startRiichiMahjong(bg), riichiFile, IntRect(314,0,2*screen.x,2*screen.y)));
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

private void startRiichiMahjong(BackgroundWorker bg)
{
	info("Riichi mahjong selected");
	startGame(
        new DefaultGameOpts,
        new DefaultDrawingOpts,
		new AiEventHandler(new SimpleAI).inBackground(bg), 
		new AiEventHandler(new SimpleAI), 
		new AiEventHandler(new SimpleAI));
}
///
unittest
{
    import fluent.asserts;
    import mahjong.domain.enums;
	setDefaultTestController;
	startRiichiMahjong;
    Controller.instance.should.be.instanceOf!IdleController;
    drawingOpts.should.be.instanceOf!DefaultDrawingOpts;
    (cast(GameController)Controller.instance).gameMode.should.equal(GameMode.Riichi);
}

private void startBambooBattle()
{
	info("Bamboo battle selected");
	startGame(
        new DefaultBambooOpts,
        new BambooDrawingOpts,
		new AiEventHandler(new SimpleAI));
}
///
unittest
{
    import fluent.asserts;
    import mahjong.domain.enums;
	setDefaultTestController;
	startBambooBattle;
    Controller.instance.should.be.instanceOf!IdleController;
    drawingOpts.should.be.instanceOf!BambooDrawingOpts;
    (cast(GameController)Controller.instance).gameMode.should.equal(GameMode.Bamboo);
}

private void startGame(
    const Opts gameOpts, DrawingOpts drawingOpts,
    GameEventHandler[] eventHandlers...)
{
    .drawingOpts = drawingOpts;
	bootEngine(eventHandlers, gameOpts);
	info("Booted game engine");
}

private void startThunderThrill()
{
	info("Thunder thrill selected");
	Controller.instance.roundUp();
	info("Opening placeholder screen");
	Controller.instance.substitute(new PlaceholderController(Controller.instance.getWindow, 
		"Coming soon.", eightPlayerChaos, IntRect(400, 0, 1050, 650)));
	trace("Swapped controller");
}

private void startSimpleMahjong()
{
	info("Simple mahjong selected");
	Controller.instance.roundUp();
	info("Opening placeholder screen");
	Controller.instance.substitute(new PlaceholderController(Controller.instance.getWindow, 
		"Coming soon.", chineseBg, IntRect(0, 0, 900, 1000)));
	trace("Swapped controller");
}

private void quit()
{
	info("Quit selected");
	Controller.instance.getWindow.close;
}



