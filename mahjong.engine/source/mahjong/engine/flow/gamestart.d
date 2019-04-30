module mahjong.engine.flow.gamestart;

import std.algorithm;
import std.experimental.logger;
import std.array;
import mahjong.domain;
import mahjong.domain.opts;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class GameStartFlow : Flow
{
	this(Metagame metagame, 
        INotificationService notificationService,
		Engine engine)
	in
	{
		assert(!metagame.players.empty, "Expected at least a single player");
	}
	body
	{
		info("Starting game.");
		super(metagame, notificationService);
		_events = metagame.players.map!((player) 
			{
				auto event = new GameStartEvent(metagame);
				engine.notify(player, event);
				return event;
			}).array;
		trace("Started game and sent out notifications to players.");
	}

	private GameStartEvent[] _events;

	override void advanceIfDone(Engine engine) 
	{
		if(isDone)
		{
			info("Started game. Switching to round start flow.");
			engine.switchFlow(new RoundStartFlow(_metagame, _notificationService, engine));
		}
	}

	private bool isDone() @property
	{
		return _events.all!(e => e.isReady);
	}
}

class GameStartEvent
{
	this(const Metagame metagame)
	{
		this.metagame = metagame;
	}

	const Metagame metagame;
	bool isReady;
}

unittest
{
    import fluent.asserts;

	auto eventHandler = new TestEventHandler;
	auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
	auto flow = new GameStartFlow(engine.metagame, new NullNotificationService, engine);
	engine.switchFlow(flow);
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!GameStartFlow.because("the players are not ready");
	eventHandler.gameStartEvent.isReady = true;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!RoundStartFlow.because("the players are ready");
}