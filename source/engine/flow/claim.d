module mahjong.engine.flow.claim;

import std.algorithm;
import std.array;
import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class ClaimFlow : Flow
{
	this(Tile tile, Metagame game, INotificationService notificationService)
	{
		trace("Constructing claim flow");
		super(game, notificationService);
		_tile = tile;
		initialiseClaimEvents;
	}

	override void advanceIfDone()
	{
		if(done) branch;
	}
		
	private:
		Tile _tile;
		ClaimEvent[] _claimEvents;

		void initialiseClaimEvents()
		{
            foreach(player; _metagame.otherPlayers)
            {
                _claimEvents ~= createEventAndNotifyHandler(player);
            }
		}

		ClaimEvent createEventAndNotifyHandler(Player player)
		{
			auto event = new ClaimEvent(_tile, player, _metagame);
			player.eventHandler.handle(event);
			return event;
		}

		bool done() @property pure const
		{
			return _claimEvents.all!(ce => ce.isHandled);
		}

		void branch()
		in
		{
			assert(_claimEvents.all!(ce => ce.isAllowed), "There should be no illegal claims");
		}
		do
		{
			if(applyRons) return;
            notifyPlayersAboutMissedTile();
			if(applyPon || applyChi)
            {
                notifyGameAboutClaimedTile;
                return;
            }
			switchFlow(new TurnEndFlow(_metagame, _notificationService));
		}

		bool applyRons()
		{
			auto rons = _claimEvents.filter!(ce => ce.request == Request.Ron);
			if(rons.empty) return false;
			info("There was a ron!");
			foreach(ron; rons) ron.apply(_notificationService);
			switchFlow(new MahjongFlow(_metagame, _notificationService));
			return true;
		}

		bool applyPon()
		{
			return applySingleClaim!(ce => ce.request == Request.Pon || ce.request == Request.Kan)();
		}

		bool applyChi()
		{
			return applySingleClaim!(ce => ce.request == Request.Chi);
		}

		bool applySingleClaim(bool function(ClaimEvent) pred)()
		{
			auto claimingEvent = _claimEvents.filter!pred;
			if(claimingEvent.empty) return false;
			claimingEvent.front.apply(_notificationService);
			switchTurn(claimingEvent.front.player);
			return true;
		}

		void switchTurn(Player newTurnPlayer)
		{
			_metagame.currentPlayer = newTurnPlayer;
			switchFlow(new TurnFlow(newTurnPlayer, _metagame, _notificationService));
		}

        void notifyPlayersAboutMissedTile()
        {
            _metagame.notifyPlayersAboutMissedTile(_tile);
        }

        void notifyGameAboutClaimedTile()
        {
            _metagame.aTileHasBeenClaimed;
        }
}

version(unittest)
{
	import mahjong.domain.enums;
    import mahjong.engine.opts;
	Metagame setup(size_t amountOfPlayers)
	{
		import std.conv;
		dstring[] names = ["Jan"d, "Piet"d, "Klaas"d, "David"d, "Henk"d, "Ingrid"d];
		Player[] players;
		for(int i = 0; i < amountOfPlayers; ++i)
		{
			auto player = new Player();
			player.startGame(i.to!PlayerWinds);
			players ~= player;
		}
		auto metagame = new Metagame(players, new DefaultGameOpts);
		metagame.currentPlayer = players[0];
		return metagame;
	}
}

unittest
{
    import fluent.asserts;
	import mahjong.engine.creation;
	auto game = setup(2);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	auto claimFlow = new ClaimFlow(ponnableTile, game, new NullNotificationService);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new NoRequest);
	assert(claimFlow.done, "Flow should be done.");
	claimFlow.advanceIfDone;
    flow.should.be.instanceOf!TurnEndFlow.because("there is no request");
    game.currentPlayer.should.equal(game.players[0]);
    player2.closedHand.tiles.length.should.equal(2);
}

unittest
{
    import fluent.asserts;
	import mahjong.engine.creation;
	auto game = setup(2);
	auto player1 = game.players[0];
	player1.startGame(PlayerWinds.north);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.isDrawnBy(player1);
	ponnableTile.isDiscarded;
	auto claimFlow = new ClaimFlow(ponnableTile, game, new NullNotificationService);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new PonRequest(player2, ponnableTile));
	claimFlow.advanceIfDone;
    flow.should.be.instanceOf!TurnFlow.because("a new turn started after claiming a tile");
    game.currentPlayer.should.equal(player2);
    player2.closedHand.tiles.length.should.equal(0);
}

unittest
{
    import fluent.asserts;
	import mahjong.engine.creation;
	auto game = setup(3);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto player3 = game.players[2];
	player3.startGame(PlayerWinds.east);
	player3.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.isNotOwn;
	ponnableTile.isDiscarded;
	auto claimFlow = new ClaimFlow(ponnableTile, game, new NullNotificationService);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new ChiRequest(player2, ponnableTile, 
			ChiCandidate(player2.game.closedHand.tiles[0], player2.game.closedHand.tiles[1]),
			game));
	claimFlow._claimEvents[1].handle(new PonRequest(player3, ponnableTile));
	claimFlow.advanceIfDone;
    flow.should.be.instanceOf!TurnFlow.because("a new turn started after claiming a tile");
    game.currentPlayer.should.equal(player3);
    player2.closedHand.tiles.length.should.equal(2);
    player3.closedHand.tiles.length.should.equal(0);
}

unittest
{
	import core.exception;
    import fluent.asserts;
	import mahjong.engine.creation;
	auto game = setup(3);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto player3 = game.players[2];
	player3.startGame(PlayerWinds.east);
	player3.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.isNotOwn;
	ponnableTile.isDiscarded;
	auto claimFlow = new ClaimFlow(ponnableTile, game, new NullNotificationService);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new NoRequest); 
	claimFlow._claimEvents[1].handle(new ChiRequest(player3, ponnableTile,
			ChiCandidate(player3.game.closedHand.tiles[0], player3.game.closedHand.tiles[1]),
			game));
    claimFlow.advanceIfDone.should.throwException!AssertError;
}

unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    scope(exit) switchFlow(null);
    auto game = setup(2);
    auto player1 = game.players[0];
    player1.startGame(PlayerWinds.north);
    auto player2 = game.players[1];
    player2.startGame(PlayerWinds.east);
    player2.game.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto ronTile = "🀡"d.convertToTiles[0];
    ronTile.isDrawnBy(player1);
	ronTile.isDiscarded;
    auto claimFlow = new ClaimFlow(ronTile, game, new NullNotificationService);
    switchFlow(claimFlow);
    claimFlow._claimEvents[0].handle(new NoRequest());
    claimFlow.advanceIfDone;
    player2.isFuriten.should.equal(true).because("player 2 did not claim a ron tile");
}

unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    scope(exit) switchFlow(null);
    auto game = setup(2);
    auto player1 = game.players[0];
    player1.startGame(PlayerWinds.north);
    player1.game.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto player2 = game.players[1];
    player2.startGame(PlayerWinds.east);
    player2.game.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto ronTile = "🀡"d.convertToTiles[0];
    ronTile.isDrawnBy(player1);
	ronTile.isDiscarded;
    auto claimFlow = new ClaimFlow(ronTile, game, new NullNotificationService);
    switchFlow(claimFlow);
    claimFlow._claimEvents[0].handle(new RonRequest(player2, ronTile, game));
    claimFlow.advanceIfDone;
    player2.isFuriten.should.equal(false)
        .because("player 2 claimed a ron tile and should not become furiten");
}

unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    scope(exit) switchFlow(null);
    auto game = setup(2);
    game.initializeRound;
    game.beginRound;
    auto player1 = game.players[0];
    player1.game.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto player2 = game.players[1];
    player2.game.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto ponTile = "🀡"d.convertToTiles[0];
    ponTile.isDrawnBy(player1);
	ponTile.isDiscarded;
    auto claimFlow = new ClaimFlow(ponTile, game, new NullNotificationService);
    switchFlow(claimFlow);
    claimFlow._claimEvents[0].handle(new PonRequest(player2, ponTile));
    claimFlow.advanceIfDone;
    game.isFirstTurn.should.equal(false).because("a tile has been claimed");
}

class ClaimEvent
{
	this(Tile tile, Player player, Metagame metagame)
	{
		this.tile = tile;
		this.player = player;
		this.metagame = metagame;
	}
	Tile tile;
	Player player;
	Metagame metagame;
	private ClaimRequest _claimRequest;

	void handle(ClaimRequest claimRequest)
	in
	{
		assert(claimRequest !is null, "When handling the claim event, the request should not be null");
	}
	body
	{
		_claimRequest = claimRequest;
	}

	bool isHandled() @property pure const
	{
		return _claimRequest !is null;
	}

	alias _claimRequest this;
}

enum Request {None, Chi, Pon, Kan, Ron}

interface ClaimRequest
{
	void apply(INotificationService notificationService);
	bool isAllowed();
	@property Request request() pure;
}

class NoRequest : ClaimRequest
{
	void apply(INotificationService notificationService)
	{
		// Do nothing.
	}

	bool isAllowed() pure
	{
		return true;
	}

	Request request() @property pure const
	{
		return Request.None;
	}
}

unittest
{
	auto noRequest = new NoRequest;
	assert(noRequest.isAllowed(), "Not having a request should always be allowed");
}

class PonRequest : ClaimRequest
{
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;

	void apply(INotificationService notificationService)
	{
		_player.pon(_discard);
		notificationService.notify(Notification.Pon, _player);
	}

	bool isAllowed() pure
	{
		return _player.isPonnable(_discard);
	}

	Request request() @property pure const
	{
		return Request.Pon;
	}
}

class KanRequest : ClaimRequest
{
	this(Player player, Tile discard, Wall wall)
	{
		_player = player;
		_discard = discard;
		_wall = wall;
	}

	private Player _player;
	private Tile _discard;
	private Wall _wall;

	void apply(INotificationService notificationService)
	{
		_player.kan(_discard, _wall);
		notificationService.notify(Notification.Kan, _player);
	}

	bool isAllowed()
	{
		return _player.isKannable(_discard, _wall);
	}

	Request request() @property pure const
	{
		return Request.Kan;
	}
}

class ChiRequest : ClaimRequest
{
	this(Player player, Tile discard, ChiCandidate chiCandidate, Metagame metagame)
	{
		_player = player;
		_discard = discard;
		_chiCandidate = chiCandidate;
		_metagame = metagame;
	}

	private Player _player;
	private Tile _discard;
	private ChiCandidate _chiCandidate;
	private Metagame _metagame;

	void apply(INotificationService notificationService)
	{
		_player.chi(_discard, _chiCandidate);
		notificationService.notify(Notification.Chi, _player);
	}

	bool isAllowed() pure
	{
		return _player.isChiable(_discard, _metagame);
	}

	Request request() @property pure const
	{
		return Request.Chi;
	}
}

class RonRequest : ClaimRequest
{
	this(Player player, Tile discard, const Metagame metagame)
	{
		_player = player;
		_discard = discard;
		_metagame = metagame;
	}

	private Player _player;
	private Tile _discard;
	private const Metagame _metagame;

	void apply(INotificationService notificationService)
	{
		_player.ron(_discard, _metagame);
		notificationService.notify(Notification.Ron, _player);
	}

	bool isAllowed()
	{
		return _player.isRonnable(_discard, _metagame);
	}

	Request request() @property pure const
	{
		return Request.Ron;
	}
}