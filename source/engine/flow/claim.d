module mahjong.engine.flow.claim;

import std.algorithm;
import std.array;
import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow;

class ClaimFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		trace("Constructing claim flow");
		super(game);
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
			_claimEvents = metagame.otherPlayers
						.map!(p => createEventAndNotifyHandler(p))
						.array;
		}

		ClaimEvent createEventAndNotifyHandler(Player player)
		{
			auto event = new ClaimEvent(_tile, player, metagame);
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
		body
		{
			if(applyRons) return;
			if(applyPon) return;
			if(applyChi) return;
			switchFlow(new TurnEndFlow(metagame));
		}

		bool applyRons()
		{
			auto rons = _claimEvents.filter!(ce => ce.request == Request.Ron);
			if(rons.empty) return false;
			info("There was a ron!");
			foreach(ron; rons) ron.apply;
			switchFlow(new MahjongFlow(metagame));
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
			claimingEvent.front.apply;
			switchTurn(claimingEvent.front.player);
			return true;
		}

		void switchTurn(Player newTurnPlayer)
		{
			metagame.currentPlayer = newTurnPlayer;
			switchFlow(new TurnFlow(newTurnPlayer, metagame));
		}
}

version(unittest)
{
	import mahjong.domain.enums;
	Metagame setup(size_t amountOfPlayers)
	{
		import std.conv;
		dstring[] names = ["Jan"d, "Piet"d, "Klaas"d, "David"d, "Henk"d, "Ingrid"d];
		Player[] players;
		for(int i = 0; i < amountOfPlayers; ++i)
		{
			auto player = new Player(new TestEventHandler, names[i]);
			player.startGame(i.to!PlayerWinds);
			players ~= player;
		}
		auto metagame = new Metagame(players);
		metagame.currentPlayer = players[0];
		return metagame;
	}
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.test.utils;
	auto game = setup(2);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	auto claimFlow = new ClaimFlow(ponnableTile, game);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new NoRequest);
	assert(claimFlow.done, "Flow should be done.");
	claimFlow.advanceIfDone;
	assert(flow.isOfType!TurnEndFlow, 
		"When there is no request, the turn should end.");
	assert(game.currentPlayer == game.players[0], "Player 1 should still be the turn player");
	assert(player2.game.closedHand.tiles.length == 2, "The player's tiles should be untouched.");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.test.utils;
	auto game = setup(2);
	auto player1 = game.players[0];
	player1.startGame(PlayerWinds.north);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.origin = player1.game;
	auto claimFlow = new ClaimFlow(ponnableTile, game);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new PonRequest(player2, ponnableTile));
	claimFlow.advanceIfDone;
	assert(flow.isOfType!TurnFlow, 
		"After claiming a pon, the flow should be in the turn flow again");
	assert(game.currentPlayer == player2, "Player 2 claimed a tile and should be the turn player");
	assert(player2.game.closedHand.tiles.empty, "The player should not have any tiles left.");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.test.utils;
	auto game = setup(3);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto player3 = game.players[2];
	player3.startGame(PlayerWinds.east);
	player3.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(PlayerWinds.south);
	auto claimFlow = new ClaimFlow(ponnableTile, game);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new ChiRequest(player2, ponnableTile, 
			ChiCandidate(player2.game.closedHand.tiles[0], player2.game.closedHand.tiles[1]),
			game));
	claimFlow._claimEvents[1].handle(new PonRequest(player3, ponnableTile));
	claimFlow.advanceIfDone;
	assert(flow.isOfType!TurnFlow, 
		"After claiming a pon, the flow should be in the turn flow again");
	assert(game.currentPlayer == player3, "Player 3 claimed a tile and should be the turn player");
	assert(player2.game.closedHand.tiles.length == 2, 
		"Player 2 should not have claimed left.");
	assert(player3.game.closedHand.tiles.empty, 
		"Player 3 should not have any tiles left as he ponned.");
}

unittest
{
	import core.exception;
	import std.exception;
	import mahjong.engine.creation;
	import mahjong.test.utils;
	auto game = setup(3);
	auto player2 = game.players[1];
	player2.startGame(PlayerWinds.east);
	player2.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto player3 = game.players[2];
	player3.startGame(PlayerWinds.east);
	player3.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(PlayerWinds.south);
	auto claimFlow = new ClaimFlow(ponnableTile, game);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new NoRequest); 
	claimFlow._claimEvents[1].handle(new ChiRequest(player3, ponnableTile,
			ChiCandidate(player3.game.closedHand.tiles[0], player3.game.closedHand.tiles[1]),
			game));
	assertThrown!AssertError(claimFlow.advanceIfDone, 
		"Player 3 should not be allowed to claim as there is a player in between");
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
	void apply();
	bool isAllowed() pure;
	@property Request request() pure;
}

class NoRequest : ClaimRequest
{
	void apply()
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

	void apply()
	{
		_player.pon(_discard);
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

	void apply()
	{
		_player.kan(_discard, _wall);
	}

	bool isAllowed() pure
	{
		return _player.isKannable(_discard);
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

	void apply()
	{
		_player.chi(_discard, _chiCandidate);
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
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;

	void apply()
	{
		_player.ron(_discard);
	}

	bool isAllowed() pure
	{
		return _player.isRonnable(_discard);
	}

	Request request() @property pure const
	{
		return Request.Ron;
	}
}