module mahjong.engine.flow.gamestart;

import std.algorithm;
import std.experimental.logger;
import std.array;
import mahjong.domain;
import mahjong.domain.opts;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class GameStartFlow : WaitForEveryPlayer!GameStartEvent 
{
	this(Metagame metagame, INotificationService notificationService, Engine engine)
	in
	{
		assert(!metagame.players.empty, "Expected at least a single player");
	}
	body
	{
		info("Starting game.");
		super(metagame, notificationService, engine);
		trace("Started game and sent out notifications to players.");
	}

	private GameStartEvent[] _events;

	protected override GameStartEvent createEvent()
	{
		return new GameStartEvent(_metagame);
	}

	protected override void advance(Engine engine)
	{
		info("Started game. Switching to round start flow.");
		engine.switchFlow(new RoundStartFlow(_metagame, _notificationService, engine));
	}
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
	eventHandler.gameStartEvent.handle;
	engine.advanceIfDone;
	engine.flow.should.be.instanceOf!RoundStartFlow.because("the players are ready");
}

final class GameStartEvent
{
	import mahjong.engine.flow.traits : SimpleEvent;

	this(const Metagame metagame)
	{
		this.metagame = metagame;
	}

	const Metagame metagame;

	mixin SimpleEvent!();
}

@("A game start event is a simple event")
unittest
{
	import fluent.asserts;
	import mahjong.engine.flow.traits;

	isSimpleEvent!GameStartEvent.should.equal(true);
}
