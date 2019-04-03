module mahjong.engine.flow.abortive;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class AbortiveDrawFlow : WaitForEveryPlayer!AbortiveDrawEvent
{
    this(Metagame game, INotificationService notificationService)
    {
        trace("Instantiating aborting draw flow");
        notificationService.notify(Notification.AbortiveDraw);
        super(game, notificationService);
    }

    protected override AbortiveDrawEvent createEvent()
    {
        return new AbortiveDrawEvent(_metagame);
    }

    protected override void advance()
    {
        _metagame.abortRound;
        flow = new RoundStartFlow(_metagame, _notificationService);
    }

    @("After an abortive draw the game resets")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.player;
        import mahjong.engine.opts;
        scope(exit) .flow = null;
        auto eventHandler = new TestEventHandler;
        auto player = new Player(eventHandler, 30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        .flow = new AbortiveDrawFlow(metagame, new NullNotificationService);
        eventHandler.abortiveDrawEvent.handle;
        .flow.advanceIfDone;
        .flow.should.be.instanceOf!RoundStartFlow;
    }

    @("After an abortive draw the game resets")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.ingame;
        import mahjong.domain.player;
        import mahjong.engine.opts;
        scope(exit) .flow = null;
        auto eventHandler = new TestEventHandler;
        auto player = new Player(eventHandler, 30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        player.game = ingame;
        player.declareRiichi(toBeDiscardedTile, metagame);
        .flow = new AbortiveDrawFlow(metagame, new NullNotificationService);
        eventHandler.abortiveDrawEvent.handle;
        .flow.advanceIfDone;
        metagame.amountOfRiichiSticks.should.equal(0);
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