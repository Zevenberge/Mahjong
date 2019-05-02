module mahjong.engine;

import mahjong.domain.metagame;
import mahjong.domain.opts;
import mahjong.domain.player;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class Engine
{
    this(GameEventHandler[] eventHandlers, const Opts opts, INotificationService notificationService)
    {
        Player[] players = new Player[eventHandlers.length];
        foreach (i, handler; eventHandlers)
        {
            auto player = new Player(opts.initialScore);
            players[i] = player;
            _players[player] = handler;
        }
        _metagame = new Metagame(players, opts);
        _notificationService = notificationService;
    }

    void boot()
    {
        _flow = new GameStartFlow(_metagame, _notificationService, this);
    }

    @("When starting the game, the game should be in the GameStartFlow")
    unittest
    {
        import fluent.asserts;

        auto eventHandler = new TestEventHandler;
        auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
        engine.boot;
        engine.flow.should.be.instanceOf!GameStartFlow;
    }

    @("A metagame has been created")
    unittest
    {
        import fluent.asserts;

        auto eventHandler = new TestEventHandler;
        auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
        engine.boot;
        auto flow = engine.flow;
        flow.metagame.should.not.beNull;
        flow.metagame.players.length.should.equal(1);
    }

    private Flow _flow;
    private GameEventHandler[const(Player)] _players;
    private Metagame _metagame;
    private INotificationService _notificationService;

    version (mahjong_test)
    {
        this(Metagame metagame)
        {
            _metagame = metagame;
            _notificationService = new NullNotificationService;
            foreach (player; metagame.players)
            {
                _players[player] = new TestEventHandler;
            }
        }

        this(Metagame metagame, GameEventHandler[] eventHandlers)
        in(metagame.players.length == eventHandlers.length, 
            "Should supply as many handlers as players")
        {
            _metagame = metagame;
            _notificationService = new NullNotificationService;
            foreach (i, player; metagame.players)
            {
                _players[player] = eventHandlers[i];
            } 
        }
    
        Metagame metagame() { return _metagame; }

        TestEventHandler getTestEventHandler(const Player player)
        {
            return cast(TestEventHandler)_players[player];
        }
    }

    void switchFlow(Flow newFlow) pure
    in(newFlow !is null, "A new flow should be supplied")
    {
        _flow = newFlow;
    }

    void terminateGame() pure
    {
        _flow = null;
    }

    package void notify(Event)(const Player player, Event event)
    {
        _players[player].handle(event);
    }

    const(Flow) flow() @property pure const
    {
        return _flow;
    }

    bool isTerminated() @property pure const
    {
        return _flow is null;
    }

    @("Can I terminate the game")
    unittest
    {
        import fluent.asserts;

        auto eventHandler = new TestEventHandler;
        auto engine = new Engine([eventHandler], new DefaultGameOpts, new NullNotificationService);
        engine.boot;
        engine.isTerminated.should.equal(false);
        engine.terminateGame;
        engine.isTerminated.should.equal(true);
    }

    void advanceIfDone()
    {
        _flow.advanceIfDone(this);
    }
}
