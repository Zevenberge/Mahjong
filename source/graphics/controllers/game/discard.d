module mahjong.graphics.controllers.game.discard;

import std.algorithm;
import std.array;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.menu.menuitem;

alias TurnOptionController = IngameOptionsController!(TurnOptionFactory, "");

class TurnOptionFactory
{
	this()
	{

	}

	private TurnOption[] _options;
	TurnOption[] options() @property
	{
		return _options;
	}

	private bool _areThereClaimOptions;
	bool areThereClaimOptions() @property
	{
		return _areThereClaimOptions;
	}
}

class TurnOption : MenuItem, IRelevantTiles
{
	this(string displayName)
	{
		super(displayName);
	}

	abstract const(Tile)[] relevantTiles() @property;
}

class CancelOption : TurnOption
{
	this()
	{
		super("Cancel");
	}

	override void select() 
	{
		(cast(TurnOptionController)controller).closeMenu;
	}

	override const(Tile)[] relevantTiles() @property
	{
		return null;
	}
}

class PromoteToKanOption : TurnOption
{
	this(Metagame metagame, Player player, Tile selectedTile, TurnEvent event)
	{
		super("Kan");
		_metagame = metagame;
		_player = player;
		_selectedTile = selectedTile;
		_event = event;
	}

	private Metagame _metagame;
	private Player _player;
	private Tile _selectedTile;
	private TurnEvent _event;

	override void select() 
	{
		controller = new IdleController(controller.getWindow, _metagame);
		_event.promoteToKan(_selectedTile);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _selectedTile ~ _player.openHand.findCorrespondingPon(_selectedTile).tiles;
	}
}

class DeclareClosedKanOption : TurnOption
{
	this(Metagame metagame, Player player, Tile selectedTile, TurnEvent event)
	{
		super("Kan");
		_metagame = metagame;
		_player = player;
		_selectedTile = selectedTile;
		_event = event;
	}

	private Metagame _metagame;
	private Player _player;
	private Tile _selectedTile;
	private TurnEvent _event;

	override void select() 
	{
		controller = new IdleController(controller.getWindow, _metagame);
		_event.declareClosedKan(_selectedTile);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.closedHand.tiles.filter!(t => _selectedTile.hasEqualValue(t)).array;
	}
}

class TsumoOption : TurnOption
{
	this(Metagame metagame, Player player, TurnEvent event)
	{
		super("Tsumo");
		_metagame = metagame;
		_player = player;
		_event = event;
	}

	private Metagame _metagame;
	private Player _player;
	private TurnEvent _event;

	override void select() 
	{
		controller = new IdleController(controller.getWindow, _metagame);
		_event.claimTsumo;
	}

	override const(Tile)[] relevantTiles() @property
	{
		return _player.closedHand.tiles ~ _player.openHand.tiles;
	}
}

class DiscardOption : TurnOption
{
	this(Metagame metagame, Tile selectedTile, TurnEvent event)
	{
		super("Kan");
		_metagame = metagame;
		_selectedTile = selectedTile;
		_event = event;
	}

	private Metagame _metagame;
	private Tile _selectedTile;
	private TurnEvent _event;

	override void select() 
	{
		controller = new IdleController(controller.getWindow, _metagame);
		_event.discard(_selectedTile);
	}

	override const(Tile)[] relevantTiles() @property
	{
		return [_selectedTile];
	}
}