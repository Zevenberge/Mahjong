module mahjong.engine.flow.abortive;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class AbortiveDrawFlow : WaitForEveryPlayer!AbortiveDrawEvent
{
    this(Metagame game, INotificationService notificationService, Engine engine)
    {
        trace("Instantiating aborting draw flow");
        notificationService.notify(Notification.AbortiveDraw);
        super(game, notificationService, engine);
    }

    protected override AbortiveDrawEvent createEvent()
    {
        return new AbortiveDrawEvent(_metagame);
    }

    protected override void advance(Engine engine)
    {
        _metagame.abortRound;
        engine.switchFlow(new RoundStartFlow(_metagame, _notificationService, engine));
    }

    @("After an abortive draw the game resets")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.player;
        import mahjong.domain.opts;
        auto eventHandler = new TestEventHandler;
        auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
        engine.metagame.initializeRound;
        engine.switchFlow(new AbortiveDrawFlow(engine.metagame, new NullNotificationService, engine));
        eventHandler.abortiveDrawEvent.handle;
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!RoundStartFlow;
    }

    @("After an abortive draw the game resets")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.ingame;
        import mahjong.domain.opts;
        import mahjong.domain.player;
        auto eventHandler = new TestEventHandler;
        auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
        engine.metagame.initializeRound;
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        engine.metagame.currentPlayer.game = ingame;
        engine.metagame.currentPlayer.declareRiichi(toBeDiscardedTile, engine.metagame);
        engine.switchFlow(new AbortiveDrawFlow(engine.metagame, new NullNotificationService, engine));
        eventHandler.abortiveDrawEvent.handle;
        engine.advanceIfDone;
        engine.metagame.amountOfRiichiSticks.should.equal(0);
    }
}

class AbortiveDrawEvent
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