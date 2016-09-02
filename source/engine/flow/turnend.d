module mahjong.engine.flow.turnend;

import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;

class TurnEndFlow : Flow
{
	this(Metagame meta)
	{
		metagame = meta;
	}
	
	override void advanceIfDone()
	{
		if(metagame.isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
			switchFlow(new ExhaustiveDrawFlow);
		}
		else if(metagame.isAbortiveDraw)
		{
			info("Abortive draw reached.");
			switchFlow(new AbortiveDrawFlow);
		}
		else
		{
			trace("Advancing to the next turn.");
			metagame.advanceTurn;
			switchFlow(new DrawFlow(metagame.currentPlayer, metagame, metagame.wall));
		}
	}
}