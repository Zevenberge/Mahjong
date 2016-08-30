module mahjong.engine.flow.turnend;

import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;

class TurnEndFlow : Flow
{
	this(Metagame meta)
	{
		_game = meta;
	}
	
	private Metagame _game;
	
	override void advanceIfDone()
	{
		if(_game.isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
			switchFlow(new ExhaustiveDrawFlow);
		}
		else if(_game.isAbortiveDraw)
		{
			info("Abortive draw reached.");
			switchFlow(new AbortiveDrawFlow);
		}
		else
		{
			trace("Advancing to the next turn.");
			_game.advanceTurn;
			switchFlow(new DrawFlow(_game.currentPlayer, _game.wall));
		}
	}
}