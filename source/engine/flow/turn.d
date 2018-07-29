module mahjong.engine.flow.turn;

import std.experimental.logger;
import std.uuid;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class TurnFlow : Flow
{
	this(Player player, Metagame meta, INotificationService notificationService)
	{
		_player = player;
		super(meta, notificationService);
		_event = new TurnEvent(this, meta, player, player.lastTile);
		_player.eventHandler.handle(_event);
	}
	
	override void advanceIfDone()
	{
		if(_event.isHandled)
		{
			assert(_flow !is null, "When the event is handled, the flow should not be null");
			advance();
		}
	}

    unittest
    {
        import mahjong.domain.enums;
        import mahjong.engine.opts;
        import mahjong.test.utils;

        auto eventHandler = new TestEventHandler;
        auto player = new Player(eventHandler);
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player]);
        auto tile = new Tile(Types.dragon, Dragons.green);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        assert(.flow.isOfType!TurnFlow, "TurnFlow should be set as flow");
        flow.advanceIfDone;
        assert(.flow.isOfType!TurnFlow, "As the player is not ready, the flow should not have advanced");
    }

	private: 
		TurnEvent _event;
		Player _player;
		Flow _flow;

		void advance()
		{
			switchFlow(_flow);
		}
		
		void discard(const Tile tile)
        in
        {
            assert(_player.canDiscard(tile), "The move should be legal.");
        }
        do
		{
			auto discard = _player.discard(tile);
			_flow = new ClaimFlow(discard, _metagame, _notificationService);
		}

		void promoteToKan(const Tile tile)
        in
        {
            assert(_player.canPromoteToKan(tile), "The move should be legal.");
        }
        do
		{
			_player.promoteToKan(tile, _metagame.wall);
			_notificationService.notify(Notification.Kan, _player);
			_flow = new TurnFlow(_player, _metagame, _notificationService);
		}

		void declareClosedKan(const Tile tile)
        in
        {
            assert(_player.canDeclareClosedKan(tile), "The move should be legal.");
        }
        do
		{
			_player.declareClosedKan(tile, _metagame.wall);
			_notificationService.notify(Notification.Kan, _player);
			_flow = new TurnFlow(_player, _metagame, _notificationService);
		}

		void claimTsumo()
        in
        {
            assert(_player.canTsumo(), "The move should be legal.");
        }
        do
		{
			info("Tsumo claimed by ", _player.name);
			_metagame.tsumo;
			_notificationService.notify(Notification.Tsumo, _player);
			_flow = new MahjongFlow(_metagame, _notificationService);
		}

        void declareRiichi(const Tile tile)
        in
        {
            assert(_player.canDeclareRiichi(tile, _metagame), "The move should be legal.");
        }
        do
        {
            info("Riichi declared by ", _player);
            auto discard = _player.declareRiichi(tile, _metagame);
            _notificationService.notify(Notification.Riichi, _player);
            _flow = new ClaimFlow(discard, _metagame, _notificationService);
        }
}

class TurnEvent
{
	this(TurnFlow flow, const Metagame metagame, const Player player, const Tile drawnTile)
	{
		_flow = flow;
		this.player = player;
		this.metagame = metagame;
		this.drawnTile = drawnTile;
	}	
	private TurnFlow _flow;
	
	private bool isHandled = false;
	
	const Player player;
	const Metagame metagame;
	const Tile drawnTile;
	
	void discard(const Tile tile)
	{
        handle;
		_flow.discard(tile);
	}

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.tile;
        import mahjong.domain.wall;
        import mahjong.engine.opts;

        class MockWall : Wall
        {
            this(Tile tileToDraw)
            {
                _tileToDraw = tileToDraw;
            }
            private Tile _tileToDraw;
            override Tile drawTile()
            {
                return _tileToDraw;
            }
        }

        gameOpts = new DefaultGameOpts;

        auto eventHandler = new TestEventHandler;
        auto player = new Player(eventHandler);
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player]);
        auto tile = new Tile(Types.dragon, Dragons.green);
        auto wall = new MockWall(tile);
        player.drawTile(wall);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        flow._event.discard(tile);
        flow.advanceIfDone;
        .flow.should.be.instanceOf!ClaimFlow.because("a tile is discarded");
    }

	void promoteToKan(const Tile tile)
	{
        handle;
		_flow.promoteToKan(tile);
	}

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.creation;
        import mahjong.engine.opts;
        gameOpts = new DefaultGameOpts;
        auto eventHandler = new TestEventHandler;
        auto player = new Player(eventHandler);
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player]);
        metagame.initializeRound;
        metagame.beginRound;
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        player.closedHand.tiles = "🀐🀘🀘"d.convertToTiles;
        player.openHand.addPon("🀐🀐🀐"d.convertToTiles);
        auto kanTile = player.closedHand.tiles[0];
        flow._event.promoteToKan(kanTile);
        flow.advanceIfDone;
        .flow.should.be.instanceOf!TurnFlow.because("the turn restarts");
        .flow.should.not.equal(flow).because("it is a new turn");
        player.openHand.amountOfKans.should.equal(1);
    }

	void declareClosedKan(const Tile tile)
	{
        handle;
		_flow.declareClosedKan(tile);
	}

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.creation;
        import mahjong.engine.opts;
        gameOpts = new DefaultGameOpts;
        auto eventHandler = new TestEventHandler;
        auto player = new Player(eventHandler);
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player]);
        metagame.initializeRound;
        metagame.beginRound;
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        player.closedHand.tiles = "🀐🀐🀐🀐🀘🀘"d.convertToTiles;
        auto kanTile = player.closedHand.tiles[0];
        flow._event.declareClosedKan(kanTile);
        flow.advanceIfDone;
        .flow.should.be.instanceOf!TurnFlow
            .because("the turn starts again if a closed kan is declared");
        .flow.should.not.equal(flow).because("it is a new turn");
        player.openHand.amountOfKans.should.equal(1);
    }

	void claimTsumo()
	{
        handle;
		_flow.claimTsumo;
	}

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.creation;
        import mahjong.engine.mahjong;
        import mahjong.engine.opts;

        auto eventHandler = new TestEventHandler;
        auto player = new Player(eventHandler);
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles = "🀐🀐🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘"d.convertToTiles;
        player.hasDrawnTheirLastTile;
        auto metagame = new Metagame([player]);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        flow._event.claimTsumo;
        flow.advanceIfDone;
        .flow.should.be.instanceOf!MahjongFlow
            .because("a tsumo is claimed");
    }

    void declareRiichi(const Tile tile)
    {
        handle;
        _flow.declareRiichi(tile);
    }

    private void handle()
    in
    {
        assert(!isHandled, "The event cannot be handled twice");
    }
    do
    {
        isHandled = true;
    }
}
