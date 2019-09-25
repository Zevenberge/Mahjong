module mahjong.graphics.controllers.game.claim;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.string;
import dsfml.graphics;
import mahjong.domain;
import mahjong.domain.chi;
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
	this(const Player player, const Tile discard, const Metagame metagame, ClaimEvent claimEvent)
	{
		auto styleOpts = .styleOpts;
		player.closedHand.displayHand;
		addRonOption(player, discard, metagame, styleOpts, claimEvent);
		addKanOption(player, discard, metagame.wall, styleOpts, claimEvent);
		addPonOption(player, discard, styleOpts, claimEvent);
		addChiOptions(player, discard, metagame, styleOpts, claimEvent);
		_areThereClaimOptions = !_options.empty;
		addDefaultOption(styleOpts, claimEvent);
	}

	private void addRonOption(const Player player, const Tile discard, 
		const Metagame metagame, StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		if(player.isRonnable(discard, metagame)) _options ~= new RonClaimOption(player, styleOpts, claimEvent);
	}

	private void addKanOption(const Player player, const Tile discard, 
		const Wall wall, StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		if(player.isKannable(discard, wall)) _options~= new KanClaimOption(player, discard, styleOpts, claimEvent);
	}

	private void addPonOption(const Player player, const Tile discard, 
		StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		if(player.isPonnable(discard)) _options ~= new PonClaimOption(player, discard, styleOpts, claimEvent);
	}

	private void addChiOptions(const Player player, const Tile discard, 
		const Metagame metagame, StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		if(!player.isChiable(discard, metagame)) return;
		auto candidates = determineChiCandidates(player.game.closedHand.tiles, discard);
		foreach(candidate; candidates)
		{
			_options ~= new ChiClaimOption(candidate, styleOpts, claimEvent);
		}
	}

	private void addDefaultOption(StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		_options ~= new NoClaimOption(styleOpts, claimEvent);
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
	import mahjong.domain.creation;
	import mahjong.domain.opts;
	import mahjong.engine.flow;
	import mahjong.graphics.opts;
	drawingOpts = new DefaultDrawingOpts;
	styleOpts = new DefaultStyleOpts;
	void assertIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.options.any!(co => cast(T)co), "ClaimOption %s not found.".format(T.stringof));
	}
	void assertNotIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.options.all!(co => !cast(T)co), "ClaimOption %s found when it should not.".format(T.stringof));
	}
	auto player = new Player();
	player.startGame(PlayerWinds.north);
	auto player2 = new Player();
	player2.startGame(PlayerWinds.east);
	auto player3 = new Player();
	player3.startGame(PlayerWinds.south);
	auto metagame = new Metagame([player, player2, player3], new DefaultGameOpts);
    metagame.initializeRound;
	metagame.currentPlayer = player;
	ClaimOptionFactory constructFactory(dstring tilesOfClaimingPlayer, dstring discard, 
		Player claimingPlayer, Player discardingPlayer)
	{
		claimingPlayer.game.closedHand.tiles = tilesOfClaimingPlayer.convertToTiles;
		auto discardedTile = discard.convertToTiles[0];
		discardedTile.isDrawnBy(discardingPlayer);
		discardedTile.isDiscarded;
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
	this(string displayName, StyleOpts styleOpts, ClaimEvent event)
	{
		super(displayName, styleOpts);
		_event = event;
	}

	override void select()
	{
		apply();
	}

	protected abstract void apply();

	private ClaimEvent _event;

	abstract const(Tile)[] relevantTiles() @property;
}

private:
class NoClaimOption : ClaimOption
{
	this(StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		super("Pass", styleOpts, claimEvent);
	}

	protected override void apply()
	{
		_event.pass();
	}

	override const(Tile)[] relevantTiles() @property
	{
		return null;
	}
}

@("No claim option has no relevant tiles")
unittest
{
	auto noClaim = new NoClaimOption(new DefaultStyleOpts, null);
	assert(noClaim.relevantTiles.empty, "When not claiming anything, there should be no relevant tiles");
}

class RonClaimOption : ClaimOption
{
	this(const Player player, StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		_player = player;
		super("Ron", styleOpts, claimEvent);
	}

	private const Player _player;

	protected override void apply()
	{
		_event.ron();
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.game.closedHand.tiles;
	}
}

unittest
{
	import mahjong.domain.creation;
	import mahjong.domain.enums;
	import mahjong.engine.flow;
	auto player = new Player();
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞"d.convertToTiles;
	auto ronOption = new RonClaimOption(player, new DefaultStyleOpts, null);
	assert(ronOption.relevantTiles.length == 13, "All of the player's on hand tiles should be relevant");
}

class KanClaimOption : ClaimOption
{
	this(const Player player, const Tile discard, StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		super("Kan", styleOpts, claimEvent);
	}

	private const Player _player;
	private const Tile _discard;

	protected override void apply()
	{
		_event.kan();
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.game.closedHand.tiles.filter!(t => _discard.hasEqualValue(t)).array;
	}
}

unittest
{
	import mahjong.domain.creation;
	import mahjong.domain.enums;
	import mahjong.engine.flow;
	auto player = new Player();
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟🀟🀟"d.convertToTiles;
	auto discard = "🀟"d.convertToTiles[0];
	auto kanOption = new KanClaimOption(player, discard, new DefaultStyleOpts, null);
	assert(kanOption.relevantTiles.length == 3, "For a kan, only three tiles are relevant");
	assert(kanOption.relevantTiles.all!(t => discard.hasEqualValue(t)), "The relevant tiles should all have the same value as the discard");
	assert(!kanOption.relevantTiles.any!(t => discard == t), "The discard itself should not be part of the relevant tiles");
}

class PonClaimOption : ClaimOption
{
	this(const Player player, const Tile discard, StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		super("Pon", styleOpts, claimEvent);
	}

	private const Player _player;
	private const Tile _discard;

	protected override void apply()
	{
		_event.pon();
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.game.closedHand.tiles.filter!(t => _discard.hasEqualValue(t)).array[0..2];
	}
}

unittest
{
	import mahjong.domain.creation;
	import mahjong.domain.enums;
	import mahjong.engine.flow;
	auto player = new Player();
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟🀟🀟"d.convertToTiles;
	auto discard = "🀟"d.convertToTiles[0];
	auto ponOption = new PonClaimOption(player, discard, new DefaultStyleOpts, null);
	assert(ponOption.relevantTiles.length == 2, "For a pon, only three tiles are relevant");
	assert(ponOption.relevantTiles.all!(t => discard.hasEqualValue(t)), "The relevant tiles should all have the same value as the discard");
	assert(!ponOption.relevantTiles.any!(t => discard == t), "The discard itself should not be part of the relevant tiles");
}

class ChiClaimOption : ClaimOption
{
	this(const ChiCandidate chiCandidate, StyleOpts styleOpts, ClaimEvent claimEvent)
	{
		_chiCandidate = chiCandidate;
		super("Chi", styleOpts, claimEvent);
	}

	private const ChiCandidate _chiCandidate;

	protected override void apply()
	{
		_event.chi(_chiCandidate);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return [_chiCandidate.first, _chiCandidate.second];
	}
}
