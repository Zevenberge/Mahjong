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
		if(metagame.isAbortiveDraw)
		{
			info("Abortive draw reached.");
			switchFlow(new AbortiveDrawFlow);
		}
		else if(metagame.isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
			switchFlow(new ExhaustiveDrawFlow);
		}
		else
		{
			trace("Advancing to the next turn.");
			metagame.advanceTurn;
			switchFlow(new DrawFlow(metagame.currentPlayer, metagame, metagame.wall));
		}
	}
}

unittest
{
	import mahjong.test.utils;
	class TestMetagame : Metagame
	{
		this()
		{
			auto eventhandler = new TestEventHandler();
			super([new Player(eventhandler), new Player(eventhandler)]);
		}

		private bool _isExhaustiveDraw;
		private bool _isAbortiveDraw;

		override bool isAbortiveDraw() @property
		{
			return _isAbortiveDraw;
		}
		override bool isExhaustiveDraw() @property 
		{
			return _isExhaustiveDraw;
		}
	}

	auto meta = new TestMetagame;
	auto turnEndFlow = new TurnEndFlow(meta);
	switchFlow(turnEndFlow);
	turnEndFlow.advanceIfDone;
	assert(flow.isOfType!DrawFlow, "While nothing is wrong, the flow did not advance to the draw flow");
	switchFlow(turnEndFlow);
	meta._isAbortiveDraw = true;
	turnEndFlow.advanceIfDone;
	assert(flow.isOfType!AbortiveDrawFlow, "If the game is in an abortive state, the flow should move to an abortive draw flow");
	switchFlow(turnEndFlow);
	meta._isExhaustiveDraw = true;
	turnEndFlow.advanceIfDone;
	assert(flow.isOfType!AbortiveDrawFlow, "If the game is in an abortive state, the flow should move to an abortive draw flow");
	switchFlow(turnEndFlow);
	meta._isAbortiveDraw = false;
	turnEndFlow.advanceIfDone;
	assert(flow.isOfType!ExhaustiveDrawFlow, "If the game has no more tiles, the flow should move to an exhaustive draw flow");
}