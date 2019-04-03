module mahjong.engine.flow.kansteal;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class KanStealFlow : Flow 
{
    this(const Tile kanTile, Metagame game, INotificationService notificationService)
    {
        trace("Constructing kan steal flow");
        super(game, notificationService);
        _kanTile = kanTile;
        notifyPlayers;
    }

    private void notifyPlayers()
    {
        foreach(player; _metagame.otherPlayers) 
        {
            auto event = createEvent(player);
            player.eventHandler.handle(event);
            _events ~= event;
        }
    }

    private KanStealEvent createEvent(Player player)
    {
        return new KanStealEvent(_kanTile, player, _metagame);
    }

    private KanStealEvent[] _events;

    override void advanceIfDone()
    {
        if(done)
        {
            advance;
        }
    }

    @("If no-one responds, the flow does not advance.")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.wall;
        import mahjong.engine.opts;
        scope(exit) switchFlow(null);
        auto kanPlayer = new Player("🀀🀀🀀🀒🀒🀒🀖🀗🀘🀙🀙🀠🀠"d);
        auto ponTile = new Tile(Types.wind, Winds.east);
        ponTile.isNotOwn;
        kanPlayer.pon(ponTile);
        auto tile = kanPlayer.closedHand.tiles[0];
        auto otherPlayer = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto metagame = new Metagame([kanPlayer, otherPlayer], new DefaultGameOpts);
        metagame.currentPlayer = kanPlayer;
        metagame.wall = new MockWall(false);
        auto flow = new KanStealFlow(tile, metagame, new NullNotificationService);
        switchFlow(flow);
        flow.advanceIfDone;
        flow.should.be.instanceOf!KanStealFlow;
    }

    @("If everyone denies, the player completes their kan and the flow moves to their turn.")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.wall;
        import mahjong.engine.opts;
        scope(exit) switchFlow(null);
        auto kanPlayer = new Player("🀀🀀🀀🀒🀒🀒🀖🀗🀘🀙🀙🀠🀠"d);
        auto ponTile = new Tile(Types.wind, Winds.east);
        ponTile.isNotOwn;
        kanPlayer.pon(ponTile);
        auto tile = kanPlayer.closedHand.tiles[0];
        auto otherPlayer = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto eventHandler = cast(TestEventHandler)otherPlayer.eventHandler;
        auto metagame = new Metagame([kanPlayer, otherPlayer], new DefaultGameOpts);
        metagame.currentPlayer = kanPlayer;
        metagame.wall = new MockWall(false);
        auto flow = new KanStealFlow(tile, metagame, new NullNotificationService);
        switchFlow(flow);
        eventHandler.kanStealEvent.pass;
        flow.advanceIfDone;
        kanPlayer.openHand.amountOfKans.should.equal(1);
        kanPlayer.openHand.amountOfPons.should.equal(1);
        .flow.should.be.instanceOf!TurnFlow;
    }
    
    @("If a tenpai player denies, they are furiten.")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.wall;
        import mahjong.engine.opts;
        scope(exit) switchFlow(null);
        auto kanPlayer = new Player("🀀🀀🀀🀒🀒🀒🀖🀗🀘🀙🀙🀠🀠"d);
        auto ponTile = new Tile(Types.wind, Winds.east);
        ponTile.isNotOwn;
        kanPlayer.pon(ponTile);
        auto tile = kanPlayer.closedHand.tiles[0];
        auto otherPlayer = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto eventHandler = cast(TestEventHandler)otherPlayer.eventHandler;
        auto metagame = new Metagame([kanPlayer, otherPlayer], new DefaultGameOpts);
        metagame.currentPlayer = kanPlayer;
        metagame.wall = new MockWall(false);
        auto flow = new KanStealFlow(tile, metagame, new NullNotificationService);
        switchFlow(flow);
        eventHandler.kanStealEvent.pass;
        flow.advanceIfDone;
        otherPlayer.isFuriten.should.equal(true);
    }

    @("If someone steals the tile, they are mahjong")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.wall;
        import mahjong.engine.opts;
        scope(exit) switchFlow(null);
        auto kanPlayer = new Player("🀀🀀🀀🀒🀒🀒🀖🀗🀘🀙🀙🀠🀠"d);
        auto ponTile = new Tile(Types.wind, Winds.east);
        ponTile.isNotOwn;
        kanPlayer.pon(ponTile);
        auto tile = kanPlayer.closedHand.tiles[0];
        auto otherPlayer = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto eventHandler = cast(TestEventHandler)otherPlayer.eventHandler;
        auto metagame = new Metagame([kanPlayer, otherPlayer], new DefaultGameOpts);
        metagame.currentPlayer = kanPlayer;
        metagame.wall = new MockWall(false);
        auto flow = new KanStealFlow(tile, metagame, new NullNotificationService);
        switchFlow(flow);
        eventHandler.kanStealEvent.steal;
        flow.advanceIfDone;
        kanPlayer.openHand.amountOfKans.should.equal(0);
        otherPlayer.isMahjong.should.equal(true);
        .flow.should.be.instanceOf!MahjongFlow;
        kanPlayer.closedHand.tiles.should.not.contain(tile);
    }

    private bool done() @property pure const 
    {
        import std.algorithm : all;
        return _events.all!(e => e.isHandled);
    }

    private void advance()
    {
        import std.algorithm : filter;
        auto steals = _events.filter!(e => e.isSteal);
        if(!steals.empty)
        {
            stealKanTile(steals);
        }
        else
        {
            completeKanDeclaration;
        }       
    }

    private void stealKanTile(Range)(Range stealingPlayers)
    {
        auto tile = _metagame.currentPlayer.closedHand.removeTile(_kanTile);
        foreach(evt; stealingPlayers)
        {
            auto player = evt._player;
            player.stealKanTile(tile, _metagame);
            _notificationService.notify(Notification.Ron, player);
        }
        switchFlow(new MahjongFlow(_metagame, _notificationService));
    }

    private void completeKanDeclaration()
    {
        auto player = _metagame.currentPlayer;
        player.promoteToKan(_kanTile, _metagame.wall);
        _metagame.notifyPlayersAboutMissedTile(_kanTile);
        _notificationService.notify(Notification.Kan, player);
        switchFlow(new TurnFlow(player, _metagame, _notificationService));
    }

    private const Tile _kanTile;
}

final class KanStealEvent
{
    import optional.optional;
    private enum Action { pass, steal}
    
    this(const Tile kanTile, Player player, Metagame metagame)
    {
        _action = none;
        _kanTile = kanTile;
        _player = player;
        _metagame = metagame;
    }

    bool isHandled() @property pure const
    {
        return _action != none;
    }

    @("By default the event is not handled")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.opts;
        auto tile = new Tile(Types.wind, Winds.east);
        auto player = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto event = new KanStealEvent(tile, player, metagame);
        event.isHandled.should.equal(false);
    }

    void steal()
    in
    {
        assert(canSteal, "The player is not allowed to steal");
    }
    do
    {
        _action = some(Action.steal);
    }

    @("If I steal, the event is handled")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.opts;
        auto tile = new Tile(Types.wind, Winds.east);
        auto player = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto event = new KanStealEvent(tile, player, metagame);
        event.steal;
        event.isHandled.should.equal(true);
    }

    bool canSteal() const 
    {
        return _player.canKanSteal(_kanTile, _metagame);
    }

    private bool isSteal() @property pure const
    {
        return _action == Action.steal;
    }

    void pass() pure
    {
        _action = some(Action.pass);
    }

    @("If I pass, the event is handled")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.opts;
        auto tile = new Tile(Types.character, Numbers.five);
        auto player = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto event = new KanStealEvent(tile, player, metagame);
        event.pass;
        event.isHandled.should.equal(true);
    }

    private Optional!Action _action;

    const(Tile) kanTile() @property pure const 
    {
        return _kanTile;
    }

    private const Tile _kanTile;

    const(Player) player() @property pure const 
    {
        return _player;
    }

    private Player _player;

    const(Metagame) metagame() @property pure const 
    {
        return _metagame;
    }

    private Metagame _metagame;
}