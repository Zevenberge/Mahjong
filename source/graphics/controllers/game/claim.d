module mahjong.graphics.controllers.game.claim;

import std.array;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow.claim;
import mahjong.graphics.controllers.game;

class ClaimController : GameController
{
	this(RenderWindow window, Metagame metagame)
	{
		super(window, metagame);
	}
}

private:

class ClaimOptionFactory
{
	this(Player player, Tile discard, Metagame metagame)
	{
		addRonOption(player, discard);
		addKanOption(player, discard);
		addPonOption(player, discard);
		addChiOptions(player, discard, metagame);
		_areThereClaimOptions = !_claimOptions.empty;
		addDefaultOption;
	}

	private void addRonOption(Player player, Tile discard)
	{
		if(player.isRonnable(discard)) _claimOptions ~= new RonClaimOption(player, discard);
	}

	private void addKanOption(Player player, Tile discard)
	{
		if(player.isKannable(discard)) _claimOptions~= new KanClaimOption(player, discard);
	}

	private void addPonOption(Player player, Tile discard)
	{
		if(player.isPonnable(discard)) _claimOptions ~= new PonClaimOption(player, discard);
	}

	private void addChiOptions(Player player, Tile discard, Metagame metagame)
	{
		if(!player.isChiable(discard, metagame)) return;
		auto candidates = determineChiCandidates(player.game.closedHand.tiles, discard);
		foreach(candidate; candidates)
		{
			_claimOptions ~= new ChiClaimOption(player, discard, candidate, metagame);
		}
	}

	private void addDefaultOption()
	{
		_claimOptions ~= new NoClaimOption;
	}

	private ClaimOption[] _claimOptions;
	ClaimOption[] claimOptions() @property
	{
		return _claimOptions;
	}

	private bool _areThereClaimOptions;
	bool areThereClaimOptions() @property
	{
		return _areThereClaimOptions;
	}
}

unittest
{
	import std.algorithm;
	import std.string;
	import mahjong.test.utils;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new DefaultGameOpts;
	void assertIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.claimOptions.any!(co => co.isOfType!T), "ClaimOption %s not found.".format(T.stringof));
	}
	void assertNotIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.claimOptions.all!(co => !co.isOfType!T), "ClaimOption %s found when it should not.".format(T.stringof));
	}
	auto player = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	player2.startGame(0);
	auto player3 = new Player(new TestEventHandler);
	player3.startGame(1);
	auto metagame = new Metagame([player, player2, player3]);
	metagame.currentPlayer = player;
	ClaimOptionFactory constructFactory(dstring tilesOfSecondPlayer, dstring discard, Player plyr)
	{
		plyr.game.closedHand.tiles = tilesOfSecondPlayer.convertToTiles;
		auto discardedTile = discard.convertToTiles[0];
		return new ClaimOptionFactory(plyr, discardedTile, metagame);
	}
	auto claimFactory = constructFactory("🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀗🀗"d, "🀡"d, player2);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀀🀁🀂🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d, "🀅"d, player2);
	assertNotIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀗🀘🀘"d, "🀖"d, player2);
	assertNotIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀗🀘🀘"d, "🀖"d, player3);
	assertNotIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀖🀗🀘🀘"d, "🀘"d, player2);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀔🀗🀘🀘🀘"d, "🀘"d, player2);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d, "🀐"d, player2);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertIn!RonClaimOption(claimFactory);

	player2.game.discards = "🀐"d.convertToTiles;
	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d, "🀐"d, player2);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);
}

class ClaimOption
{
	abstract ClaimRequest constructRequest();
}

class NoClaimOption : ClaimOption
{
	override ClaimRequest constructRequest() 
	{
		return new NoRequest;
	}
}

class RonClaimOption : ClaimOption
{
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;

	override ClaimRequest constructRequest() 
	{
		return new RonRequest(_player, _discard);
	}
}

class KanClaimOption : ClaimOption
{
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;
	override ClaimRequest constructRequest() 
	{
		return new KanRequest(_player, _discard);
	}
}

class PonClaimOption : ClaimOption
{
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;

	override ClaimRequest constructRequest() 
	{
		return new PonRequest(_player, _discard);
	}
}

class ChiClaimOption : ClaimOption
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

	override ClaimRequest constructRequest() 
	{
		return new ChiRequest(_player, _discard, _chiCandidate, _metagame);
	}
}