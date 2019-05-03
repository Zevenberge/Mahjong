module mahjong.graphics.controllers.game.idle;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.graphics.controllers.game;

class IdleController : GameController
{
	this(const Metagame metagame, Engine engine)
	{
		trace("Intantiating idle controller");
		super(metagame, engine);
	}

	protected override void handleGameKey(Event.KeyEvent key) 
	{
		// Do nothing
	}

}
