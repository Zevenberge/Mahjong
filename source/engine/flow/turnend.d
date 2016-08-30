module mahjong.engine.flow.turnend;

import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;

class TurnEndFlow : Flow
{
	this(Metagame meta)
	{
		_meta = meta;
	}
	
	private Metagame _meta;
	
	override void advanceIfDone()
	{
		if(_meta.isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
			switchFlow(new ExhaustiveDrawFlow);
		}
		else if(_meta.isAbortiveDraw)
		{
			info("Abortive draw reached.");
			switchFlow(new AbortiveDrawFlow);
		}
		else
		{
			trace("Advancing to the next turn.");
			_meta.advanceTurn;
			switchFlow(new DrawFlow(_meta.currentPlayer, _meta.wall));
		}
	}
}