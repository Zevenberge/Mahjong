module mahjong.engine.flow.roundstart;

import std.algorithm;
import std.experimental.logger;
import mahjong.domain;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class RoundStartFlow :WaitForEveryPlayer!RoundStartEvent
{
	this(Metagame metagame, INotificationService notificationService, Engine engine)
	{
		info("Starting round.");
		metagame.initializeRound;
		super(metagame, notificationService, engine);
	}

	protected override RoundStartEvent createEvent()
	{
		return new RoundStartEvent(_metagame);
	}

	protected override void advance(Engine engine) 
	{
			info("All players are ready. Initialising game");
			_metagame.beginRound;
			info("Started round. Switching to draw flow");
			engine.switchFlow(new DrawFlow(_metagame.currentPlayer, _metagame, 
					_metagame.wall, _notificationService));
	}
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
	eventhandler.roundStartEvent.handle;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!DrawFlow.because("the players want to move on");
    metagame.currentPlayer.should.equal(player);
    metagame.round.should.equal(1);
}

final class RoundStartEvent
{
	import mahjong.engine.flow.traits : SimpleEvent;

	this(const Metagame metagame)
	{
		this.metagame = metagame;
	}

	const Metagame metagame;

	mixin SimpleEvent!();
}

@("A round start event is a simple event")
unittest
{
	import fluent.asserts;
    import mahjong.engine.flow.traits;
	isSimpleEvent!RoundStartEvent.should.equal(true);
}