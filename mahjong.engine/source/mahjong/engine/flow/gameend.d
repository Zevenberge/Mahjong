module mahjong.engine.flow.gameend;

import std.algorithm.searching : all;
import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class GameEndFlow : WaitForEveryPlayer!GameEndEvent
{
	this(Metagame metagame, INotificationService notificationService, Engine engine)
	{
		trace("Constructing game end flow");
		super(metagame, notificationService, engine);
	}

    protected override GameEndEvent createEvent()
    {
        return new GameEndEvent(_metagame);
    }

	protected override void advance(Engine engine)
    {
		info("Game ended. Releasing flow.");
		engine.terminateGame;
	}
}

class GameEndEvent
{
	this(Metagame metagame)
	{
		this.metagame = metagame;
	}

	const Metagame metagame;

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
    import fluent.asserts;
    import mahjong.domain.opts;
    import mahjong.domain.player;
	auto metagame = new Metagame([new Player], new DefaultGameOpts);
	auto engine = new Engine(metagame);
	auto gameEndFlow = new GameEndFlow(metagame, new NullNotificationService, engine);
	engine.switchFlow(gameEndFlow);
	engine.advanceIfDone;
    engine.isTerminated.should.equal(false);
    engine.flow.should.equal(gameEndFlow);
}

unittest
{
    import fluent.asserts;
    import mahjong.domain.opts;
    import mahjong.domain.player;
	auto eventHandler = new TestEventHandler;
	auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
	auto gameEndFlow = new GameEndFlow(engine.metagame, new NullNotificationService, engine);
    eventHandler.gameEndEvent.should.not.beNull;
}

unittest
{
    import fluent.asserts;
    import mahjong.domain.opts;
    import mahjong.domain.player;
	auto eventHandler = new TestEventHandler;
	auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
	auto gameEndFlow = new GameEndFlow(engine.metagame, new NullNotificationService, engine);
	engine.switchFlow(gameEndFlow);
	eventHandler.gameEndEvent.handle;
	engine.advanceIfDone;
    engine.isTerminated.should.equal(true);
}