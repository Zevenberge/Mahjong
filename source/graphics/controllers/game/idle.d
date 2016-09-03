module mahjong.graphics.controllers.game.idle;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.graphics.controllers.game;

class IdleController : GameController
{
	this(RenderWindow window, Metagame metagme)
	{
		trace("Intantiating idle controller");
		super(window, metagme);
	}

	protected override void handleGameKey(Event.KeyEvent key) 
	{
		// Do nothing
	}

}
