module mahjong.graphics.controllers.game.turnoption;

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
	this(Player player, Tile selectedTile, Metagame metagame, TurnEvent turnEvent)
	{
		addTsumoOption(metagame, player, turnEvent);
		addPromoteToKanOption(metagame, player, selectedTile, turnEvent);
		addDeclareClosedKanOption(metagame, player, selectedTile, turnEvent);
		addDiscardOption(metagame, selectedTile, turnEvent);
		_isDiscardTheOnlyOption = _options.length == 1;
		addCancelOption;
	}

	private void addTsumoOption(Metagame metagame, Player player, TurnEvent turnEvent)
	{
		if(!player.isMahjong) return;
		_options ~= new TsumoOption(metagame, player, turnEvent);
	}

	private void addPromoteToKanOption(Metagame metagame, Player player, Tile selectedTile, TurnEvent turnEvent)
	{
		if(!player.canPromoteToKan(selectedTile)) return;
		_options ~= new PromoteToKanOption(metagame, player, selectedTile, turnEvent);
	}

	private void addDeclareClosedKanOption(Metagame metagame, Player player, Tile selectedTile, TurnEvent turnEvent)
	{
		if(!player.canDeclareClosedKan(selectedTile)) return;
		_options ~= new DeclareClosedKanOption(metagame, player, selectedTile, turnEvent);
	}

	private void addDiscardOption(Metagame metagame, Tile selectedTile, TurnEvent turnEvent)
	{
		_options = new DiscardOption(metagame, selectedTile, turnEvent) ~_options;
	}

	private void addCancelOption()
	{
		_options ~= new CancelOption;
	}

	private TurnOption[] _options;
	TurnOption[] options() @property
	{
		return _options;
	}

	private bool _isDiscardTheOnlyOption;
	bool isDiscardTheOnlyOption() @property
	{
		return _isDiscardTheOnlyOption;
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