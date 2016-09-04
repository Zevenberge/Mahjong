module mahjong.engine.flow.gamestart;

import std.algorithm;
import std.experimental.logger;
import std.array;
import mahjong.domain;
import mahjong.engine.flow;

class GameStartFlow : Flow
{
	this(GameEventHandler[] eventHandlers)
	in
	{
		assert(!eventHandlers.empty, "Expected at least a single event handler");
	}
	body
	{
		info("Starting game.");
		auto players = eventHandlers.map!(d => new Player(d)).array;
		metagame = new Metagame(players);
		_events = eventHandlers.map!((handler) 
			{
				auto event = new GameStartEvent(metagame);
				handler.handle(event);
				return event;
			}).array;
		trace("Started game and sent out notifications to players.");
	}

	private GameStartEvent[] _events;

	override void advanceIfDone() 
	{
		if(isDone)
		{
			info("Started game. Switching to round start flow.");
			switchFlow(new RoundStartFlow(metagame));
		}
	}

	private bool isDone() @property
	{
		return _events.all!(e => e.isReady);
	}
}

class GameStartEvent
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

	writeln("Testing game start flow");
	gameOpts = new DefaultGameOpts ;


	auto eventHandler = new TestEventHandler;
	auto flow = new GameStartFlow([eventHandler]);
	assert(flow.metagame.players.length == 1, "One player should have been created");
	switchFlow(flow);
	assert(typeid(.flow) == typeid(GameStartFlow), "GameStartFlow should be set as flow");
	writeln("Testing whether the flow advances when it should not");
	flow.advanceIfDone;
	assert(typeid(.flow) == typeid(GameStartFlow), "As the players are not ready, the flow should not have advanced");
	eventHandler.gameStartEvent.isReady = true;
	writeln("Testing whether the flow advances when it should");
	flow.advanceIfDone;
	assert(typeid(.flow) == typeid(RoundStartFlow), "As the players are ready, the flow should have advanced to the start of the round");
	writeln("Game start flow test succeeded.");
}