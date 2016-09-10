module mahjong.engine.flow.roundstart;

import std.algorithm;
import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;

class RoundStartFlow : Flow
{
	this(Metagame metagame)
	{
		info("Starting round.");
		this.metagame = metagame;
		metagame.nextRound;
		foreach(player; metagame.players)
		{
			auto event = new RoundStartEvent(metagame);
			_events ~= event;
			player.eventHandler.handle(event);
		}
	}

	private RoundStartEvent[] _events;

	override void advanceIfDone() 
	{
		if(isDone)
		{
			info("All players are ready. Initialising game");
			metagame.beginRound;
			info("Started round. Switching to draw flow");
			switchFlow(new DrawFlow(metagame.currentPlayer, metagame, metagame.wall));
		}
	}

	private bool isDone() @property
	{
		return _events.all!(e => e.isReady);
	}
}

class RoundStartEvent
{
	this(Metagame metagame)
	{
		this.metagame = metagame;
	}

	Metagame metagame;
	bool isReady;
}

unittest
{
	import std.stdio;
	import mahjong.engine.opts;
	import mahjong.test.utils;

	writeln("Testing round start flow");
	gameOpts = new DefaultGameOpts;

	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	auto metagame = new Metagame([player]);
	auto flow = new RoundStartFlow(metagame);
	switchFlow(flow);
	assert(.flow.isOfType!RoundStartFlow, "RoundStartFlow should be set as flow");
	assert(metagame.currentPlayer is null, "As the game is not started, there should be no turn player");
	writeln("Testing whether the flow advances when it should not");
	flow.advanceIfDone;
	assert(.flow.isOfType!RoundStartFlow, "As the players are not ready, the flow should not have advanced");
	eventHandler.roundStartEvent.isReady = true;
	writeln("Testing whether the flow advances when it should");
	flow.advanceIfDone;
	assert(.flow.isOfType!DrawFlow, "As the players are ready, the flow should have advanced to the start of the turn (draw flow)");
	assert(metagame.currentPlayer == player, "The only player should be in turn now");
	writeln("Round start flow test succeeded.");
}