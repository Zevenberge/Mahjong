module mahjong.engine.flow.roundstart;

import std.algorithm;
import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class RoundStartFlow : Flow
{
	this(Metagame metagame, INotificationService notificationService)
	{
		info("Starting round.");
		super(metagame, notificationService);
		metagame.initializeRound;
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
			_metagame.beginRound;
			info("Started round. Switching to draw flow");
			switchFlow(new DrawFlow(_metagame.currentPlayer, _metagame, 
					_metagame.wall, _notificationService));
		}
	}

	private bool isDone() @property
	{
		return _events.all!(e => e.isReady);
	}
}

class RoundStartEvent
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
	import mahjong.engine.opts;

	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler, 30_000);
	auto metagame = new Metagame([player], new DefaultGameOpts);
	auto flow = new RoundStartFlow(metagame, new NullNotificationService);
	switchFlow(flow);
    .flow.should.be.instanceOf!RoundStartFlow;
	flow.advanceIfDone;
    .flow.should.be.instanceOf!RoundStartFlow.because("the players are not yet ready");
	eventHandler.roundStartEvent.isReady = true;
	flow.advanceIfDone;
    .flow.should.be.instanceOf!DrawFlow.because("the players want to move on");
    metagame.currentPlayer.should.equal(player);
    metagame.round.should.equal(1);
}