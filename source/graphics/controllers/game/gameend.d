module mahjong.graphics.controllers.game.gameend;

import std.experimental.logger : info;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu.mainmenucontroller;
import mahjong.graphics.drawing.gameend;
import mahjong.graphics.drawing.result;
import mahjong.graphics.menu.creation.mainmenu;
import mahjong.graphics.opts : styleOpts;
import mahjong.graphics.utils : freeze;

class GameEndController : MahjongController
{
	this(RenderWindow window, Metagame metagame, GameEndEvent event)
	{
		super(window, metagame, freezeGameGraphicsOnATexture(metagame));
		_screen = new GameEndScreen(metagame, innerScreenBounds);
		_event = event;
	}

	private RenderTexture freezeGameGraphicsOnATexture(Metagame metagame)
	{
		auto screen = styleOpts.screenSize;
		return freeze!((target) {})(Vector2u(screen.x, screen.y));
	}

	private GameEndEvent _event;
	private GameEndScreen _screen;

	override void draw() 
	{
		super.draw;
		_screen.draw(_window);
	}

	protected override void advanceScreen() 
	{
		info("Rounding up game.");
		_event.handle;
		controller = new MainMenuController(_window, composeMainMenu);
	}
}

unittest
{
	// Check no segfaults test.
	import dsfml.graphics : Event, Keyboard;
	import mahjong.domain.player;
	import mahjong.engine.flow;
	import mahjong.graphics.drawing.player;
	import mahjong.graphics.rendersprite;
	import mahjong.test.utils;
	import mahjong.test.window;
	scope(exit) controller = null;
	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.draw(new RenderSprite(FloatRect()), 0);
	auto metagame = new Metagame([player, player, player, player]);
	auto window = new TestWindow;
	auto event = new GameEndEvent(metagame);
	controller = new GameEndController(window, metagame, event);
	controller.draw;
	Event keyEvent = Event(Event.EventType.KeyReleased);
	keyEvent.key = Event.KeyEvent(Keyboard.Key.Return, false, false, false, false);
	controller.handleEvent(keyEvent);
	assert(event.isHandled, "After pressing enter, the event should have been handled.");
	assert(controller.isOfType!MainMenuController, "After a game, the user is returned to the main manu.");
}