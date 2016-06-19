module mahjong.graphics.controllers.game.singleplayercontroller;

import std.algorithm;
import std.array;
import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import mahjong.engine.ai;
import mahjong.engine.gamefront;
import mahjong.graphics.controllers.game.gamecontroller;

class SinglePlayerController : GameController
{
	this(RenderWindow window, GameFront[] gameFronts)
	{
		trace("Constructing single player controller. Got ", gameFronts.length, " players");
		super(window, gameFronts);
		initialiseAI;
	}
	
	override void yield()
	{
		foreach_reverse(ai; _ais)
		{
			ai.interact;
		}
		_ownGameFront.start;
	}
	
	private void initialiseAI()
	{
		trace("Initialising AI");
		_ais = _gameFronts[1..$].map!(f => new RandomAI(f).to!AI).array;
		trace("Initialised AI");
	}
	private AI[] _ais;
}