module mahjong.engine.flow.turn;

import std.experimental.logger;
import std.typecons;
import std.uuid;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class TurnFlow : Flow
{
    this(Player player, Metagame meta, INotificationService notificationService, Engine engine)
    {
        _player = player;
        super(meta, notificationService);
        _event = new TurnEvent(meta, player, player.lastTile);
        engine.notify(player, _event);
    }

    override void advanceIfDone(Engine engine)
    {
        if (_event.isHandled)
        {
            advance(engine);
        }
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.opts;

        auto player = new Player();
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto engine = new Engine(metagame);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        engine.flow.should.be.instanceOf!TurnFlow;
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!TurnFlow.because("the player is not ready");
    }

private:
    TurnEvent _event;
    Player _player;

    void advance(Engine engine)
    {
        final switch (_event._chosenAction)
        {
        case Action.unknown:
            assert(false, "Cannot advance when the action is not known");
        case Action.discard:
            discard(_event._selectedTile, engine);
            break;
        case Action.promoteToKan:
            promoteToKan(_event._selectedTile, engine);
            break;
        case Action.declareClosedKan:
            declareClosedKan(_event._selectedTile, engine);
            break;
        case Action.tsumo:
            claimTsumo(engine);
            break;
        case Action.declareRiichi:
            declareRiichi(_event._selectedTile, engine);
            break;
        case Action.declareRedraw:
            declareRedraw(engine);
            break;
        }
    }

    void discard(const Tile tile, Engine engine)
    in(_player.canDiscard(tile), "Trying to discard a tile which can't be discarded.")
    {
        auto discard = _player.discard(tile);
        engine.switchFlow(new ClaimFlow(discard, _metagame, _notificationService, engine));
    }

    void promoteToKan(const Tile tile, Engine engine)
    in(_player.canPromoteToKan(tile), "Trying to promote to kan while it can't")
    {
        engine.switchFlow(new KanStealFlow(tile, _metagame, _notificationService, engine));
    }

    void declareClosedKan(const Tile tile, Engine engine)
    in(_player.canDeclareClosedKan(tile), "Trying to declare closed kan while it can't")
    {
        _player.declareClosedKan(tile, _metagame.wall);
        _notificationService.notify(Notification.Kan, _player);
        engine.switchFlow(new TurnFlow(_player, _metagame, _notificationService, engine));
    }

    void claimTsumo(Engine engine)
    in(_player.canTsumo(_metagame), "Trying to tsumo while it can't")
    {
        info("Tsumo claimed by ", _player.name);
        _metagame.tsumo;
        _notificationService.notify(Notification.Tsumo, _player);
        engine.switchFlow(new MahjongFlow(_metagame, _notificationService, engine));
    }

    void declareRiichi(const Tile tile, Engine engine)
    in(_player.canDeclareRiichi(tile, _metagame), "Trying to declare riichi while it can't")
    {
        info("Riichi declared by ", _player);
        auto discard = _player.declareRiichi(tile, _metagame);
        _notificationService.notify(Notification.Riichi, _player);
        engine.switchFlow(new ClaimFlow(discard, _metagame, _notificationService, engine));
    }

    void declareRedraw(Engine engine)
    in(_player.isEligibleForRedraw(_metagame), "A player should be allowed to force a redraw.")
    {
        info("Redraw forced by ", _player);
        _metagame.declareRedraw;
        _notificationService.notify(Notification.AbortiveDraw, _player);
        engine.switchFlow(new AbortiveDrawFlow(_metagame, _notificationService, engine));
    }
}

final class TurnEvent
{
    this(const Metagame metagame, const Player player, const Tile drawnTile)
    {
        this.player = player;
        this.metagame = metagame;
        this.drawnTile = drawnTile;
    }

    const Player player;
    const Metagame metagame;
    const Tile drawnTile;

    bool isHandled() @property pure const
    {
        return _chosenAction != Action.unknown;
    }

    private Action _chosenAction = Action.unknown;
    private Rebindable!(const(Tile)) _selectedTile;

    void discard(const Tile tile)
    in(!isHandled, "The event can't be handled twice")
    {
        _chosenAction = Action.discard;
        _selectedTile = tile;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.opts;
        import mahjong.domain.tile;
        import mahjong.domain.wall;

        class MockWall : Wall
        {
            this(Tile tileToDraw)
            {
                super(new DefaultGameOpts);
                _tileToDraw = tileToDraw;
            }

            private Tile _tileToDraw;
            override Tile drawTile()
            {
                return _tileToDraw;
            }
        }

        auto player = new Player();
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto tile = new Tile(Types.dragon, Dragons.green);
        auto wall = new MockWall(tile);
        player.drawTile(wall);
        auto engine = new Engine(metagame);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        flow._event.discard(tile);
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!ClaimFlow.because("a tile is discarded");
    }

    void promoteToKan(const Tile tile)
    in(!isHandled, "The event can't be handled twice")
    {
        _chosenAction = Action.promoteToKan;
        _selectedTile = tile;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.enums;
        import mahjong.domain.opts;

        auto player = new Player();
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        auto engine = new Engine(metagame);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        player.closedHand.tiles = "🀐🀘🀘"d.convertToTiles;
        player.openHand.addPon("🀐🀐🀐"d.convertToTiles);
        auto kanTile = player.closedHand.tiles[0];
        flow._event.promoteToKan(kanTile);
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!KanStealFlow.because("the tile can still be claimed");
        player.openHand.amountOfKans.should.equal(0).because("it can still be cancelled");
    }

    void declareClosedKan(const Tile tile)
    in(!isHandled, "The event can't be handled twice")
    {
        _chosenAction = Action.declareClosedKan;
        _selectedTile = tile;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.enums;
        import mahjong.domain.opts;

        auto player = new Player();
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        auto engine = new Engine(metagame);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        player.closedHand.tiles = "🀐🀐🀐🀐🀘🀘"d.convertToTiles;
        auto kanTile = player.closedHand.tiles[0];
        flow._event.declareClosedKan(kanTile);
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!TurnFlow.because(
                "the turn starts again if a closed kan is declared");
        engine.flow.should.not.equal(flow).because("it is a new turn");
        player.openHand.amountOfKans.should.equal(1);
    }

    void claimTsumo()
    in(!isHandled, "The event can't be handled twice")
    {
        _chosenAction = Action.tsumo;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.enums;
        import mahjong.domain.mahjong;
        import mahjong.domain.opts;

        auto player = new Player();
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles
            = "🀐🀐🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘"d.convertToTiles;
        player.hasDrawnTheirLastTile;
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto engine = new Engine(metagame);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        flow._event.claimTsumo;
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!MahjongFlow.because("a tsumo is claimed");
    }

    void declareRiichi(const Tile tile)
    in(!isHandled, "The event can't be handled twice")
    {
        _chosenAction = Action.declareRiichi;
        _selectedTile = tile;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.enums;
        import mahjong.domain.mahjong;
        import mahjong.domain.opts;

        auto player = new Player();
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles
            = "🀐🀐🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘"d.convertToTiles;
        player.hasDrawnTheirLastTile;
        auto engine = new Engine(metagame);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        flow._event.declareRiichi(player.closedHand.tiles[0]);
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!ClaimFlow.because(
                "a riichi results in a regular discard");
        player.isRiichi.should.equal(true);
    }

    void declareRedraw()
    in(!isHandled, "The event can't be handled twice")
    {
        _chosenAction = Action.declareRedraw;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.enums;
        import mahjong.domain.mahjong;
        import mahjong.domain.opts;

        auto player = new Player();
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles
            = "🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d.convertToTiles;
        auto engine = new Engine(metagame);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        flow._event.declareRedraw;
        engine.advanceIfDone;
        engine.flow.should.be.instanceOf!AbortiveDrawFlow.because("the game should be aborted");
        metagame.isAbortiveDraw.should.equal(true)
            .because("the metagame itself should also be aborted");
    }
}

@("A turn event is not a simple event")
unittest
{
    import fluent.asserts;
    import mahjong.engine.flow.traits;
    isSimpleEvent!TurnEvent.should.equal(false);
}

enum Action
{
    unknown,
    discard,
    promoteToKan,
    declareClosedKan,
    tsumo,
    declareRiichi,
    declareRedraw
}