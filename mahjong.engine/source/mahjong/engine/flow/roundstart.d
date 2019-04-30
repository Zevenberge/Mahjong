module mahjong.engine.flow.roundstart;

import std.algorithm;
import std.experimental.logger;
import mahjong.domain;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class RoundStartFlow : Flow
{
	this(Metagame metagame, INotificationService notificationService, Engine engine)
	{
		info("Starting round.");
		super(metagame, notificationService);
		metagame.initializeRound;
		foreach(player; metagame.players)
		{
			auto event = new RoundStartEvent(metagame);
			_events ~= event;
			engine.notify(player, event);
		}
	}

	private RoundStartEvent[] _events;

	override void advanceIfDone(Engine engine) 
	{
		if(isDone)
		{
			info("All players are ready. Initialising game");
			_metagame.beginRound;
			info("Started round. Switching to draw flow");
			engine.switchFlow(new DrawFlow(_metagame.currentPlayer, _metagame, 
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
	import mahjong.domain.opts;

	auto player = new Player();
	auto metagame = new Metagame([player], new DefaultGameOpts);
	auto engine = new Engine(metagame);
	auto eventhandler = engine.getTestEventHandler(player);
	auto flow = new RoundStartFlow(metagame, new NullNotificationService, engine);
	engine.switchFlow(flow);
    engine.flow.should.be.instanceOf!RoundStartFlow;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!RoundStartFlow.because("the players are not yet ready");
	eventhandler.roundStartEvent.isReady = true;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!DrawFlow.because("the players want to move on");
    metagame.currentPlayer.should.equal(player);
    metagame.round.should.equal(1);
}