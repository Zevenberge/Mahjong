module mahjong.graphics.controllers.game.claim;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.string;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow.claim;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.opts;

alias ClaimController = IngameOptionsController!(ClaimOptionFactory, "Claim tile?");

class ClaimOptionFactory
{
	this(Player player, Tile discard, Metagame metagame, ClaimEvent claimEvent)
	{
		player.closedHand.displayHand;
		addRonOption(player, discard, claimEvent);
		addKanOption(player, discard, metagame.wall, claimEvent);
		addPonOption(player, discard, claimEvent);
		addChiOptions(player, discard, metagame, claimEvent);
		_areThereClaimOptions = !_options.empty;
		addDefaultOption(claimEvent);
	}

	private void addRonOption(Player player, Tile discard, ClaimEvent claimEvent)
	{
		if(player.isRonnable(discard)) _options ~= new RonClaimOption(player, discard, claimEvent);
	}

	private void addKanOption(Player player, Tile discard, Wall wall, ClaimEvent claimEvent)
	{
		if(player.isKannable(discard, wall)) _options~= new KanClaimOption(player, discard, wall, claimEvent);
	}

	private void addPonOption(Player player, Tile discard, ClaimEvent claimEvent)
	{
		if(player.isPonnable(discard)) _options ~= new PonClaimOption(player, discard, claimEvent);
	}

	private void addChiOptions(Player player, Tile discard, Metagame metagame, ClaimEvent claimEvent)
	{
		if(!player.isChiable(discard, metagame)) return;
		auto candidates = determineChiCandidates(player.game.closedHand.tiles, discard);
		foreach(candidate; candidates)
		{
			_options ~= new ChiClaimOption(player, discard, candidate, metagame, claimEvent);
		}
	}

	private void addDefaultOption(ClaimEvent claimEvent)
	{
		_options ~= new NoClaimOption(claimEvent);
	}

	private ClaimOption[] _options;
	ClaimOption[] options() @property
	{
		return _options;
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
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	import mahjong.graphics.opts;
	import mahjong.test.utils;
	gameOpts = new DefaultGameOpts;
	drawingOpts = new DefaultDrawingOpts;
	styleOpts = new DefaultStyleOpts;
	void assertIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.options.any!(co => co.isOfType!T), "ClaimOption %s not found.".format(T.stringof));
	}
	void assertNotIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.options.all!(co => !co.isOfType!T), "ClaimOption %s found when it should not.".format(T.stringof));
	}
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.north);
	auto player2 = new Player(new TestEventHandler);
	player2.startGame(PlayerWinds.east);
	auto player3 = new Player(new TestEventHandler);
	player3.startGame(PlayerWinds.south);
	auto metagame = new Metagame([player, player2, player3]);
    metagame.initializeRound;
	metagame.currentPlayer = player;
	ClaimOptionFactory constructFactory(dstring tilesOfClaimingPlayer, dstring discard, 
		Player claimingPlayer, Player discardingPlayer)
	{
		claimingPlayer.game.closedHand.tiles = tilesOfClaimingPlayer.convertToTiles;
		auto discardedTile = discard.convertToTiles[0];
		discardedTile.origin = discardingPlayer.game;
		return new ClaimOptionFactory(claimingPlayer, discardedTile, metagame, 
			new ClaimEvent(discardedTile, claimingPlayer, metagame));
	}
	auto claimFactory = constructFactory("🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀗🀗"d, "🀡"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀀🀁🀂🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d, "🀅"d, player2, player);
	assertNotIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀗🀘🀘"d, "🀖"d, player2, player);
	assertNotIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀗🀘🀘"d, "🀖"d, player3, player);
	assertNotIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀖🀗🀘🀘"d, "🀘"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀔🀗🀘🀘🀘"d, "🀘"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertIn!KanClaimOption(claimFactory);
	assertNotIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d, "🀐"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertIn!RonClaimOption(claimFactory);

	auto discards = "🀐"d.convertToTiles;
	player2.game.setDiscards(discards);
	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d, "🀐"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	discards[0].claim; // Claim the discard such that it is no longer in the discard pile.
	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d, "🀐"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);
}

class ClaimOption : MenuItem, IRelevantTiles
{
	abstract ClaimRequest constructRequest();

	this(string displayName, ClaimEvent event)
	{
		super(displayName);
		_event = event;
	}

	override void select()
	{
		(cast(ClaimController)Controller.instance).finishedSelecting;
		info("Idle controller swapped");
		_event.handle(constructRequest);
	}

	private ClaimEvent _event;

	abstract const(Tile)[] relevantTiles() @property;
}

private:
class NoClaimOption : ClaimOption
{
	this(ClaimEvent claimEvent)
	{
		super("Pass", claimEvent);
	}

	override ClaimRequest constructRequest() 
	{
		return new NoRequest;
	}

	override const(Tile)[] relevantTiles() @property
	{
		return null;
	}
}

unittest
{
	auto noClaim = new NoClaimOption(null);
	assert(noClaim.relevantTiles.empty, "When not claiming anything, there should be no relevant tiles");
}

class RonClaimOption : ClaimOption
{
	this(Player player, Tile discard, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		super("Ron", claimEvent);
	}

	private Player _player;
	private Tile _discard;

	override ClaimRequest constructRequest() 
	{
		return new RonRequest(_player, _discard);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.game.closedHand.tiles;
	}
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞"d.convertToTiles;
	auto discard = "🀟"d.convertToTiles[0];
	auto ronOption = new RonClaimOption(player, discard, null);
	assert(ronOption.relevantTiles.length == 13, "All of the player's on hand tiles should be relevant");
	assert(!ronOption.relevantTiles.any!(t => discard == t), "The discard itself should not be part of the relevant tiles");
}

class KanClaimOption : ClaimOption
{
	this(Player player, Tile discard, Wall wall, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		_wall = wall;
		super("Kan", claimEvent);
	}

	private Player _player;
	private Tile _discard;
	private Wall _wall;
	override ClaimRequest constructRequest() 
	{
		return new KanRequest(_player, _discard, _wall);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.game.closedHand.tiles.filter!(t => _discard.hasEqualValue(t)).array;
	}
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟🀟🀟"d.convertToTiles;
	auto discard = "🀟"d.convertToTiles[0];
	auto kanOption = new KanClaimOption(player, discard, null, null);
	assert(kanOption.relevantTiles.length == 3, "For a kan, only three tiles are relevant");
	assert(kanOption.relevantTiles.all!(t => discard.hasEqualValue(t)), "The relevant tiles should all have the same value as the discard");
	assert(!kanOption.relevantTiles.any!(t => discard == t), "The discard itself should not be part of the relevant tiles");
}

class PonClaimOption : ClaimOption
{
	this(Player player, Tile discard, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		super("Pon", claimEvent);
	}

	private Player _player;
	private Tile _discard;

	override ClaimRequest constructRequest() 
	{
		return new PonRequest(_player, _discard);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.game.closedHand.tiles.filter!(t => _discard.hasEqualValue(t)).array[0..2];
	}
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟🀟🀟"d.convertToTiles;
	auto discard = "🀟"d.convertToTiles[0];
	auto ponOption = new PonClaimOption(player, discard, null);
	assert(ponOption.relevantTiles.length == 2, "For a pon, only three tiles are relevant");
	assert(ponOption.relevantTiles.all!(t => discard.hasEqualValue(t)), "The relevant tiles should all have the same value as the discard");
	assert(!ponOption.relevantTiles.any!(t => discard == t), "The discard itself should not be part of the relevant tiles");
}

class ChiClaimOption : ClaimOption
{
	this(Player player, Tile discard, ChiCandidate chiCandidate, Metagame metagame, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		_chiCandidate = chiCandidate;
		_metagame = metagame;
		super("Chi", claimEvent);
	}

	private Player _player;
	private Tile _discard;
	private ChiCandidate _chiCandidate;
	private Metagame _metagame;

	override ClaimRequest constructRequest() 
	{
		return new ChiRequest(_player, _discard, _chiCandidate, _metagame);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return [_chiCandidate.first, _chiCandidate.second];
	}
}
