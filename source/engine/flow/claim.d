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
		const Tile _tile;
		ClaimEvent[] _claimEvents;

		void initialiseClaimEvents()
		{
			_claimEvents = metagame.otherPlayers
						.map!(p => createEventAndNotifyHandler(p))
						.array;
		}

		ClaimEvent createEventAndNotifyHandler(Player player)
		{
			auto event = new ClaimEvent(_tile, player);
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
			switchFlow(new TurnEndFlow(metagame));
		}
}

version(unittest)
{
	Metagame setup(size_t amountOfPlayers)
	{
		Player[] players;
		for(int i = 0; i < amountOfPlayers; ++i)
		{
			auto player = new Player(new TestEventHandler);
			player.startGame(i);
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
	player2.startGame(0);
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
	auto player2 = game.players[1];
	player2.startGame(0);
	player2.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	auto claimFlow = new ClaimFlow(ponnableTile, game);
	switchFlow(claimFlow);
	claimFlow._claimEvents[0].handle(new PonRequest(player2, ponnableTile));
	claimFlow.advanceIfDone;
	assert(flow.isOfType!TurnFlow, 
		"After claiming a pon, the flow should be in the turn flow again");
	assert(game.currentPlayer == player2, "Player 2 claimed a tile and should be the turn player");
	assert(player2.game.closedHand.tiles.empty, "The player should not have any tiles left.");
}

class ClaimEvent
{
	this(const Tile tile, Player player)
	{
		this.tile = tile;
		this.player = player;
	}
	const Tile tile;
	Player player;
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

	bool isAllowed() @property pure
	{
		return _claimRequest.isAllowed;
	}
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
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;

	void apply()
	{
		_player.kan(_discard);
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
	this(Player player, Tile discard, ChiCandidate chiCandidate)
	{
		_player = player;
		_discard = discard;
		_chiCandidate = chiCandidate;
	}

	private Player _player;
	private Tile _discard;
	private ChiCandidate _chiCandidate;

	void apply()
	{
		_player.chi(_discard, _chiCandidate);
	}

	bool isAllowed() pure
	{
		return _player.isChiable(_discard);
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
		// Do nothing
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