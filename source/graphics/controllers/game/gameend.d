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

class GameEndController : ResultController
{
	this(RenderWindow window, const Metagame metagame, GameEndEvent event)
	{
		super(window, metagame, freezeGameGraphicsOnATexture(metagame));
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

	override void draw() 
	{
		super.draw;
		_screen.draw(_window);
	}

	protected override void advanceScreen() 
	{
		info("Rounding up game.");
		_event.handle;
        Controller.instance.substitute(new MainMenuController(_window, composeMainMenu));
	}
}

unittest
{
	// Check no segfaults test.
	import dsfml.graphics : Event, Keyboard;
    import fluent.asserts;
	import mahjong.domain.player;
    import mahjong.domain.wrappers;
	import mahjong.engine.flow;
    import mahjong.engine.opts;
	import mahjong.graphics.drawing.player;
	import mahjong.graphics.rendersprite;
	import mahjong.test.window;
	scope(exit) setDefaultTestController;
	auto player = new Player();
	player.draw(AmountOfPlayers(4), new RenderSprite(FloatRect()), 0);
	auto metagame = new Metagame([player, player, player, player], new DefaultGameOpts);
	auto window = new TestWindow;
	auto event = new GameEndEvent(metagame);
    setDefaultTestController;
	Controller.instance.substitute(new GameEndController(window, metagame, event));
	Controller.instance.draw;
	Event keyEvent = Event(Event.EventType.KeyReleased);
	keyEvent.key = Event.KeyEvent(Keyboard.Key.Return, false, false, false, false);
	Controller.instance.handleEvent(keyEvent);
	assert(event.isHandled, "After pressing enter, the event should have been handled.");
    Controller.instance.should.be.instanceOf!MainMenuController
        .because("after a game, the user is returned to the main menu");
}