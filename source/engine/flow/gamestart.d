module mahjong.engine.flow.gamestart;

import std.algorithm;
import std.experimental.logger;
import std.array;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.engine.notifications;
import mahjong.engine.opts;

class GameStartFlow : Flow
{
	this(GameEventHandler[] eventHandlers, Opts gameOpts,
        INotificationService notificationService)
	in
	{
		assert(!eventHandlers.empty, "Expected at least a single event handler");
        assert(gameOpts !is null, "Options were not supplied");
	}
	body
	{
		info("Starting game.");
        auto players = eventHandlers.map!(eh => new Player(eh, gameOpts.initialScore)).array;
        auto game = new Metagame(players, gameOpts);
		super(game, notificationService);
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
			switchFlow(new RoundStartFlow(_metagame, _notificationService));
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
	auto flow = new GameStartFlow([eventHandler], new DefaultGameOpts, new NullNotificationService);
    flow.metagame.should.not.beNull;
    flow.metagame.players.length.should.equal(1);
	switchFlow(flow);
    .flow.should.be.instanceOf!GameStartFlow;
	flow.advanceIfDone;
    .flow.should.be.instanceOf!GameStartFlow.because("the players are not ready");
	eventHandler.gameStartEvent.isReady = true;
	flow.advanceIfDone;
    .flow.should.be.instanceOf!RoundStartFlow.because("the players are ready");
}