module mahjong.engine.flow.gameend;

import std.algorithm.searching : all;
import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class GameEndFlow : WaitForEveryPlayer!GameEndEvent
{
	this(Metagame metagame, INotificationService notificationService)
	{
		trace("Constructing game end flow");
		super(metagame, notificationService);
	}

    protected override GameEndEvent createEvent()
    {
        return new GameEndEvent(_metagame);
    }

	protected override void advance()
    {
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
    import mahjong.domain.player;
    import mahjong.engine.opts;
	auto metagame = new Metagame([new Player], new DefaultGameOpts);
	auto gameEndFlow = new GameEndFlow(metagame, new NullNotificationService);
	flow = gameEndFlow;
	flow.advanceIfDone;
    flow.should.not.beNull;
    flow.should.equal(gameEndFlow);
}

unittest
{
    import fluent.asserts;
    import mahjong.domain.player;
    import mahjong.engine.opts;
	auto eventHandler = new TestEventHandler;
	auto metagame = new Metagame([new Player(eventHandler, 30_000)], new DefaultGameOpts);
	auto gameEndFlow = new GameEndFlow(metagame, new NullNotificationService);
    eventHandler.gameEndEvent.should.not.beNull;
}

unittest
{
    import fluent.asserts;
    import mahjong.domain.player;
    import mahjong.engine.opts;
	auto eventHandler = new TestEventHandler;
	auto metagame = new Metagame([new Player(eventHandler, 30_000)], new DefaultGameOpts);
	auto gameEndFlow = new GameEndFlow(metagame, new NullNotificationService);
	flow = gameEndFlow;
	eventHandler.gameEndEvent.handle;
	flow.advanceIfDone;
    flow.should.beNull;
}