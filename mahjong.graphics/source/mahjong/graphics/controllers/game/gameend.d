﻿module mahjong.graphics.controllers.game.gameend;

import std.experimental.logger : info;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu.mainmenucontroller;
import mahjong.graphics.drawing.gameend;
import mahjong.graphics.drawing.result;
import mahjong.graphics.menu.creation.mainmenu;
import mahjong.graphics.opts : styleOpts;
import mahjong.graphics.utils : freeze;

class GameEndController : ResultController
{
	this(const Metagame metagame, GameEndEvent event, Engine engine)
	{
		super(metagame, freezeGameGraphicsOnATexture(metagame), engine);
		_screen = new GameEndScreen(metagame, innerScreenBounds);
		_event = event;
	}

	private RenderTexture freezeGameGraphicsOnATexture(const Metagame metagame)
	{
		auto screen = styleOpts.screenSize;
		return freeze!((target) {})(Vector2u(screen.x, screen.y));
	}

	private GameEndEvent _event;
	private GameEndScreen _screen;

	override void draw(RenderTarget target) 
	{
		super.draw(target);
		_screen.draw(target);
	}

	protected override void advanceScreen() 
	{
		info("Rounding up game.");
		_event.handle;
        Controller.instance.substitute(new MainMenuController(getMainMenu()));
	}
}

unittest
{
	// Check no segfaults test.
    import fluent.asserts;
    import mahjong.domain.opts;
	import mahjong.domain.player;
    import mahjong.domain.wrappers;
	import mahjong.engine.flow;
	import mahjong.graphics.drawing.player;
	import mahjong.graphics.rendersprite;
    import mahjong.test.key;
	import mahjong.test.window;
	scope(exit) setDefaultTestController;
	auto player = new Player();
	player.draw(AmountOfPlayers(4), new RenderSprite(FloatRect()), 0);
	auto metagame = new Metagame([player, player, player, player], new DefaultGameOpts);
	auto window = new TestWindow;
	composeMainMenu(window, null);
	scope(exit) cleanupMainMenu;
	auto event = new GameEndEvent(metagame);
    auto engine = new Engine(metagame);
    setDefaultTestController;
	Controller.instance.substitute(new GameEndController(metagame, event, engine));
	Controller.instance.draw(window);
    Controller.instance.handleEvent(returnKeyPressed);
	assert(event.isHandled, "After pressing enter, the event should have been handled.");
    Controller.instance.should.be.instanceOf!MainMenuController
        .because("after a game, the user is returned to the main menu");
}