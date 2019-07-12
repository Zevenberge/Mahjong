module mahjong.graphics.controllers.game;

public import mahjong.graphics.controllers.game.abortive;
public import mahjong.graphics.controllers.game.claim;
public import mahjong.graphics.controllers.game.exhaustive;
public import mahjong.graphics.controllers.game.gameend;
public import mahjong.graphics.controllers.game.idle;
public import mahjong.graphics.controllers.game.kansteal;
public import mahjong.graphics.controllers.game.mahjong;
public import mahjong.graphics.controllers.game.popup;
public import mahjong.graphics.controllers.game.options;
public import mahjong.graphics.controllers.game.result;
public import mahjong.graphics.controllers.game.transfer;
public import mahjong.graphics.controllers.game.turn;
public import mahjong.graphics.controllers.game.turnoption;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain;
import mahjong.domain.enums;
import mahjong.engine;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game.pause;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.menu;

class GameController : Controller
{
	protected this(const Metagame metagame, Engine engine)
	{
		_metagame = metagame;
		_engine = engine;
	}

	const(Metagame) metagame() { return _metagame;} @property pure
	protected const Metagame _metagame;
	protected Engine _engine;

	override void draw(RenderTarget target)
	{
		target.clear;
		drawGameBg(target);
		_metagame.draw(target);
	}

	final override bool handleKeyEvent(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Escape:
				pauseGame;
				break;
			default:
				handleGameKey(key);
				break;
		}
		return false;
	}

	@("If I press escape, the pause menu is overlaid")
	unittest
	{
		import fluent.asserts;
		import mahjong.graphics.opts;
		import mahjong.test.key;
		scope(exit) Controller.cleanUp;
        styleOpts = new DefaultStyleOpts;
		auto controller = new TestGameController();
		Controller.instance.substitute(controller);
		controller.handleEvent(escapeKeyPressed);
		controller.has!PauseOverlay.should.equal(true);
	}

	protected void pauseGame()
	{
		Controller.instance.add(new PauseOverlay());
	}

	protected abstract void handleGameKey(Event.KeyEvent key);

	override void roundUp() 
	{
		info("Rouding up game comtroller.");
		_engine.terminateGame;
		clearCache;
	}

	override void yield() 
	{
		_engine.advanceIfDone;
	}

    final GameMode gameMode() @property pure const
    {
        return _metagame.gameMode;
    }
}

version(unittest)
{
	class TestGameController : GameController
	{
		this()
		{
			import mahjong.domain.opts;
			import mahjong.engine.flow.eventhandler;
			import mahjong.engine.notifications;
			auto engine = new Engine([new TestEventHandler, new TestEventHandler],
				new DefaultGameOpts, new NullNotificationService);
			super(engine.metagame, engine);
		}

		protected override void handleGameKey(Event.KeyEvent key) {}
	}
}