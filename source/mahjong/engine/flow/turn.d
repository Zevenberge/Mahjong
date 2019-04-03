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
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.opts;

        auto player = new Player();
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto tile = new Tile(Types.dragon, Dragons.green);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        .flow.should.be.instanceOf!TurnFlow;
        flow.advanceIfDone;
        .flow.should.be.instanceOf!TurnFlow.because("the player is not ready");
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
			_flow = new KanStealFlow(tile, _metagame, _notificationService);
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
            assert(_player.canTsumo(_metagame), "The move should be legal.");
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

        void declareRedraw()
        in
        {
            assert(_player.isEligibleForRedraw(_metagame), "A player should be allowed to force a redraw.");
        }
        do
        {
            info("Redraw forced by ", _player);
            _metagame.declareRedraw;
            _notificationService.notify(Notification.AbortiveDraw, _player);
            _flow = new AbortiveDrawFlow(_metagame, _notificationService);
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
        auto player = new Player();
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        player.closedHand.tiles = "🀐🀘🀘"d.convertToTiles;
        player.openHand.addPon("🀐🀐🀐"d.convertToTiles);
        auto kanTile = player.closedHand.tiles[0];
        flow._event.promoteToKan(kanTile);
        flow.advanceIfDone;
        .flow.should.be.instanceOf!KanStealFlow.because("the tile can still be claimed");
        player.openHand.amountOfKans.should.equal(0).because("it can still be cancelled");
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
        auto player = new Player();
        player.startGame(PlayerWinds.east);
        auto metagame = new Metagame([player], new DefaultGameOpts);
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

        auto player = new Player();
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles = "🀐🀐🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘"d.convertToTiles;
        player.hasDrawnTheirLastTile;
        auto metagame = new Metagame([player], new DefaultGameOpts);
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

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.creation;
        import mahjong.engine.mahjong;
        import mahjong.engine.opts;

        auto player = new Player();
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles = "🀐🀐🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘"d.convertToTiles;
        player.hasDrawnTheirLastTile;
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        flow._event.declareRiichi(player.closedHand.tiles[0]);
        flow.advanceIfDone;
        .flow.should.be.instanceOf!ClaimFlow
            .because("a riichi results in a regular discard");
        player.isRiichi.should.equal(true);
    }

    void declareRedraw()
    {
        handle;
        _flow.declareRedraw;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.engine.creation;
        import mahjong.engine.mahjong;
        import mahjong.engine.opts;

        auto player = new Player();
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles = "🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d.convertToTiles;
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        switchFlow(flow);
        flow._event.declareRedraw;
        flow.advanceIfDone;
        .flow.should.be.instanceOf!AbortiveDrawFlow
            .because("the game should be aborted");
        metagame.isAbortiveDraw.should.equal(true)
            .because("the metagame itself should also be aborted");
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
