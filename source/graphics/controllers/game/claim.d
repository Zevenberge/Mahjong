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
import mahjong.graphics.drawing.tile;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.opts;

class ClaimController : MenuController
{
	this(RenderWindow window, 
		Metagame metagame,
		Controller innerController,
		ClaimOptionFactory factory)
	{
		auto menu = new Menu("Claim tile?");
		foreach(option; factory.claimOptions)
		{
			menu.addOption(option);
		}
		menu.configureGeometry;
		menu.selectOption(factory.claimOptions.back);
		super(window, innerController, menu);
		_metagame = metagame;
	}

	private Metagame _metagame;

	void swapIdleController()
	{
		auto idleController = cast(IdleController)_innerController;
		if(!idleController)
		{
			idleController = new IdleController(_window, _metagame);
		}
		controller = idleController;
	}

	override void draw() 
	{
		if(controller == this) 
		{
			super.draw;
			drawMarkersOnRelevantTiles;
		}
		else _innerController.draw;
	}

	private void drawMarkersOnRelevantTiles()
	{
		auto selectedOption = cast(ClaimOption)_menu.selectedItem;
		auto rectangleShape = new RectangleShape(drawingOpts.tileSize);
		rectangleShape.fillColor = Color(250, 255, 141, 146);
		foreach(tile; selectedOption.relevantTiles)
		{
			rectangleShape.position = tile.getCoords.position;
			_window.draw(rectangleShape);
		}
	}

	protected override bool menuClosed() 
	{
		controller = new MenuController(_window, this, getPauseMenu);
		return false;
	}

	protected override RectangleShape constructHaze() 
	{
		auto margin = Vector2f(styleOpts.claimMenuMargin, styleOpts.claimMenuMargin);
		auto menuBounds = _menu.getGlobalBounds;
		auto haze = new RectangleShape(menuBounds.size + margin*2);
		haze.fillColor = Color(100, 100, 100, 158);
		haze.position = menuBounds.position - margin;
		return haze;
	}
}

class ClaimOptionFactory
{
	this(Player player, Tile discard, Metagame metagame, ClaimEvent claimEvent)
	{
		player.game.showHand;
		addRonOption(player, discard, claimEvent);
		addKanOption(player, discard, claimEvent);
		addPonOption(player, discard, claimEvent);
		addChiOptions(player, discard, metagame, claimEvent);
		_areThereClaimOptions = !_claimOptions.empty;
		addDefaultOption(claimEvent);
	}

	private void addRonOption(Player player, Tile discard, ClaimEvent claimEvent)
	{
		if(player.isRonnable(discard)) _claimOptions ~= new RonClaimOption(player, discard, claimEvent);
	}

	private void addKanOption(Player player, Tile discard, ClaimEvent claimEvent)
	{
		if(player.isKannable(discard)) _claimOptions~= new KanClaimOption(player, discard, claimEvent);
	}

	private void addPonOption(Player player, Tile discard, ClaimEvent claimEvent)
	{
		if(player.isPonnable(discard)) _claimOptions ~= new PonClaimOption(player, discard, claimEvent);
	}

	private void addChiOptions(Player player, Tile discard, Metagame metagame, ClaimEvent claimEvent)
	{
		if(!player.isChiable(discard, metagame)) return;
		auto candidates = determineChiCandidates(player.game.closedHand.tiles, discard);
		foreach(candidate; candidates)
		{
			_claimOptions ~= new ChiClaimOption(player, discard, candidate, metagame, claimEvent);
		}
	}

	private void addDefaultOption(ClaimEvent claimEvent)
	{
		_claimOptions ~= new NoClaimOption(claimEvent);
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
	import mahjong.graphics.opts;
	gameOpts = new DefaultGameOpts;
	drawingOpts = new DefaultDrawingOpts;
	styleOpts = new DefaultStyleOpts;
	void assertIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.claimOptions.any!(co => co.isOfType!T), "ClaimOption %s not found.".format(T.stringof));
	}
	void assertNotIn(T)(ClaimOptionFactory factory)
	{
		assert(factory.claimOptions.all!(co => !co.isOfType!T), "ClaimOption %s found when it should not.".format(T.stringof));
	}
	auto player = new Player(new TestEventHandler);
	player.startGame(3);
	auto player2 = new Player(new TestEventHandler);
	player2.startGame(0);
	auto player3 = new Player(new TestEventHandler);
	player3.startGame(1);
	auto metagame = new Metagame([player, player2, player3]);
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

	player2.game.setDiscards("🀐"d.convertToTiles);
	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d, "🀐"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);

	player2.game.discards[0].claim; // Claim the discard such that it is no longer in the discard pile.
	claimFactory = constructFactory("🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d, "🀐"d, player2, player);
	assertIn!PonClaimOption(claimFactory);
	assertIn!NoClaimOption(claimFactory);
	assertNotIn!KanClaimOption(claimFactory);
	assertIn!ChiClaimOption(claimFactory);
	assertNotIn!RonClaimOption(claimFactory);
}

class ClaimOption : MenuItem
{
	abstract ClaimRequest constructRequest();

	this(string displayName, ClaimEvent event)
	{
		super(displayName, &select);
		_event = event;
	}

	void select()
	{
		trace("Claim option ", typeid(this), " selected. Swapping out ", typeid(controller));
		(cast(ClaimController)controller).swapIdleController;
		trace("Idle controller swapped");
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
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞"d.convertToTiles;
	auto discard = "🀟"d.convertToTiles[0];
	auto ronOption = new RonClaimOption(player, discard, null);
	assert(ronOption.relevantTiles.length == 13, "All of the player's on hand tiles should be relevant");
	assert(!ronOption.relevantTiles.any!(t => discard == t), "The discard itself should not be part of the relevant tiles");
}

class KanClaimOption : ClaimOption
{
	this(Player player, Tile discard, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		super("Kan", claimEvent);
	}

	private Player _player;
	private Tile _discard;
	override ClaimRequest constructRequest() 
	{
		return new KanRequest(_player, _discard);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.game.closedHand.tiles.filter!(t => _discard.hasEqualValue(t)).array;
	}
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟🀟🀟"d.convertToTiles;
	auto discard = "🀟"d.convertToTiles[0];
	auto kanOption = new KanClaimOption(player, discard, null);
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
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
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
