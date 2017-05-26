module mahjong.graphics.controllers.game.claim;

import std.array;
import std.string;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow.claim;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.menu;

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

	protected override bool menuClosed() 
	{
		controller = new MenuController(_window, this, getPauseMenu);
		return false;
	}
}

private:

class ClaimOptionFactory
{
	this(Player player, Tile discard, Metagame metagame, ClaimEvent claimEvent)
	{
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
		return new ClaimOptionFactory(plyr, discardedTile, metagame, new ClaimEvent(discardedTile, plyr));
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

class ClaimOption : MenuItem
{
	abstract ClaimRequest constructRequest();

	this(string displayName, ClaimEvent event)
	{
		super(displayName, &select);
	}

	void select()
	{
		(cast(ClaimController)controller).swapIdleController;
		_event.handle(constructRequest);
	}

	private ClaimEvent _event;
}

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
}

class ChiClaimOption : ClaimOption
{
	this(Player player, Tile discard, ChiCandidate chiCandidate, Metagame metagame, ClaimEvent claimEvent)
	{
		_player = player;
		_discard = discard;
		_chiCandidate = chiCandidate;
		_metagame = metagame;
		super("Chi %s%s".format(chiCandidate.first.face, chiCandidate.second.face), claimEvent);
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
