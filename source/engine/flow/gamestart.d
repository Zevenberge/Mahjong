module mahjong.engine.flow.gamestart;

import std.algorithm;
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
		auto players = eventHandlers.map!(d => new Player(d)).array;
		metagame = new Metagame(players);
		_events = eventHandlers.map!(_ => new GameStartEvent(metagame)).array;
	}

	private GameStartEvent[] _events;

	override void advanceIfDone() 
	{
		if(isDone)
		{
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
