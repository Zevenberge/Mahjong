module mahjong.engine.flow.gameend;

import std.algorithm.searching : all;
import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;

class GameEndFlow : Flow
{
	this(Metagame metagame)
	{
		trace("Constructing game end flow");
		super(metagame);
		notifyPlayers;
	}

	private void notifyPlayers()
	{
		foreach(player; metagame.players)
		{
			auto event = new GameEndEvent(metagame);
			_events ~= event;
			player.eventHandler.handle(event);
		}
	}

	private GameEndEvent[] _events;

	override void advanceIfDone()
	{
		if(!_events.all!(e => e.isHandled)) return;
		info("Game ended. Releasing flow.");
		flow = null;
	}
}

class GameEndEvent
{
	this(Metagame metagame)
	{
		this.metagame = metagame;
	}

	Metagame metagame;

	private bool _isHandled;
	bool isHandled() @property
	{
		return _isHandled;
	}

	void handle()
	{
		_isHandled = true;
	}
}

unittest
{
	auto eventHandler = new TestEventHandler;
	auto metagame = new Metagame([eventHandler.createPlayer]);
	auto gameEndFlow = new GameEndFlow(metagame);
	flow = gameEndFlow;
	flow.advanceIfDone;
	assert(flow !is null, "as no-one confirmed, the flow should not be null");
	assert(flow == gameEndFlow, "The flow should still be the game end flow.");
}

unittest
{
	auto eventHandler = new TestEventHandler;
	auto metagame = new Metagame([eventHandler.createPlayer]);
	auto gameEndFlow = new GameEndFlow(metagame);
	assert(eventHandler.gameEndEvent !is null, "A game end event shouldbe distributed to each player");
}

unittest
{
	auto eventHandler = new TestEventHandler;
	auto metagame = new Metagame([eventHandler.createPlayer]);
	auto gameEndFlow = new GameEndFlow(metagame);
	flow = gameEndFlow;
	eventHandler.gameEndEvent.handle;
	flow.advanceIfDone;
	assert(flow is null, "When every player agreed that the game ended, the flow should resolve itself");
}