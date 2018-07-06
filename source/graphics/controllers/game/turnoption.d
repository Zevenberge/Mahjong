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
    this(const Player player, const Tile selectedTile, const Metagame metagame, TurnEvent turnEvent)
    {
        addTsumoOption(metagame, player, turnEvent);
        addPromoteToKanOption(metagame, player, selectedTile, turnEvent);
        addDeclareClosedKanOption(metagame, player, selectedTile, turnEvent);
        addDiscardOption(metagame, selectedTile, turnEvent);
        _isDiscardTheOnlyOption = _options.length == 1;
        addCancelOption;
    }

    private void addTsumoOption(const Metagame metagame, const Player player, TurnEvent turnEvent)
    {
        if(!player.canTsumo) return;
        auto tsumoOption = new TsumoOption(metagame, player, turnEvent);
        _options ~= tsumoOption;
        _defaultOption = tsumoOption;
    }

    private void addPromoteToKanOption(const Metagame metagame, const Player player, 
        const Tile selectedTile, TurnEvent turnEvent)
    {
        if(!player.canPromoteToKan(selectedTile)) return;
        _options ~= new PromoteToKanOption(metagame, player, selectedTile, turnEvent);
    }

    private void addDeclareClosedKanOption(const Metagame metagame, const Player player, 
        const Tile selectedTile, TurnEvent turnEvent)
    {
        if(!player.canDeclareClosedKan(selectedTile)) return;
        _options ~= new DeclareClosedKanOption(metagame, player, selectedTile, turnEvent);
    }

    private void addDiscardOption(const Metagame metagame, const Tile selectedTile, TurnEvent turnEvent)
    {
        auto discardOption = new DiscardOption(metagame, selectedTile, turnEvent);
        _options = discardOption ~ _options;
        if(_defaultOption is null)
        {
            _defaultOption = discardOption;
        }
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

    private TurnOption _defaultOption;
    TurnOption defaultOption() @property
    {
        return _defaultOption;
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

    final override void select() 
    {
        (cast(TurnOptionController)Controller.instance).closeMenu;
    }

    override const(Tile)[] relevantTiles() @property
    {
        return null;
    }
}

class AssertiveTurnOption : TurnOption
{
    this(string displayName)
    {
        super(displayName);
    }

    final override void select() 
    {
        (cast(TurnOptionController)Controller.instance).finishedSelecting;
        apply;
    }

    protected abstract void apply();
}

class PromoteToKanOption : AssertiveTurnOption
{
    this(const Metagame metagame, const Player player, const Tile selectedTile, TurnEvent event)
    {
        super("Kan");
        _metagame = metagame;
        _player = player;
        _selectedTile = selectedTile;
        _event = event;
    }

    private const Metagame _metagame;
    private const Player _player;
    private const Tile _selectedTile;
    private TurnEvent _event;

    protected override void apply() 
    {
        _event.promoteToKan(_selectedTile);
    }

    override const(Tile)[] relevantTiles() @property
    {
        return _selectedTile ~ _player.openHand.findCorrespondingPon(_selectedTile).tiles;
    }
}

class DeclareClosedKanOption : AssertiveTurnOption
{
    this(const Metagame metagame, const Player player, const Tile selectedTile, TurnEvent event)
    {
        super("Kan");
        _metagame = metagame;
        _player = player;
        _selectedTile = selectedTile;
        _event = event;
    }

    private const Metagame _metagame;
    private const Player _player;
    private const Tile _selectedTile;
    private TurnEvent _event;

    protected override void apply() 
    {
        _event.declareClosedKan(_selectedTile);
    }

    override const(Tile)[] relevantTiles() @property
    {
        return _player.closedHand.tiles.filter!(t => _selectedTile.hasEqualValue(t)).array;
    }
}

class TsumoOption : AssertiveTurnOption
{
    this(const Metagame metagame, const Player player, TurnEvent event)
    {
        super("Tsumo");
        _metagame = metagame;
        _player = player;
        _event = event;
    }

    private const Metagame _metagame;
    private const Player _player;
    private TurnEvent _event;

    protected override void apply() 
    {
        _event.claimTsumo;
    }

    override const(Tile)[] relevantTiles() @property
    {
        return _player.closedHand.tiles ~ _player.openHand.tiles;
    }
}

class DiscardOption : AssertiveTurnOption
{
    this(const Metagame metagame, const Tile selectedTile, TurnEvent event)
    {
        super("Discard");
        _metagame = metagame;
        _selectedTile = selectedTile;
        _event = event;
    }

    private const Metagame _metagame;
    private const Tile _selectedTile;
    private TurnEvent _event;

    protected override void apply() 
    {
        _event.discard(_selectedTile);
    }

    override const(Tile)[] relevantTiles() @property
    {
        return [_selectedTile];
    }
}

version(unittest)
{
    import std.algorithm;
    import std.string;
    import mahjong.engine.creation;
    import mahjong.engine.flow;
    import mahjong.engine.notifications;
    import mahjong.test.utils;
    void assertIn(T)(TurnOptionFactory factory)
    {
        assert(factory.options.any!(co => co.isOfType!T), 
            "TurnOption %s not found.".format(T.stringof));
    }
    void assertNotIn(T)(TurnOptionFactory factory)
    {
        assert(factory.options.all!(co => !co.isOfType!T), 
            "TurnOption %s found when it should not.".format(T.stringof));
    }
    TurnOptionFactory constructFactory(dstring tilesOfTurnPlayer, size_t indexOfDiscard, 
        Player player, Metagame metagame)
    {
        player.closedHand.tiles = tilesOfTurnPlayer.convertToTiles;
        auto discardedTile = player.closedHand.tiles[indexOfDiscard];
        return new TurnOptionFactory(player, discardedTile, metagame, 
            new TurnEvent(new TurnFlow(player, metagame, new NullNotificationService),
                metagame, player, discardedTile));
    }
}

unittest
{
    import std.array;
    auto eventHandler = new TestEventHandler;
    auto player = new Player(eventHandler);
    auto metagame = new Metagame([player]);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀀🀁🀂🀃🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d;
    auto factory = constructFactory(tiles, 13, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertNotIn!PromoteToKanOption(factory);
    assertNotIn!DeclareClosedKanOption(factory);
    assertNotIn!TsumoOption(factory);
    assert(factory.defaultOption.isOfType!DiscardOption, "The discard option should be the default");
    assert(factory.isDiscardTheOnlyOption, "Only the discard option should be in there.");
}

unittest
{
    import std.array;
    auto eventHandler = new TestEventHandler;
    auto player = new Player(eventHandler);
    auto metagame = new Metagame([player]);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d;
    auto factory = constructFactory(tiles, 0, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertNotIn!PromoteToKanOption(factory);
    assertNotIn!DeclareClosedKanOption(factory);
    assertIn!TsumoOption(factory);
    assert(factory.defaultOption.isOfType!TsumoOption, "The tsumo option should be the default");
    assert(!factory.isDiscardTheOnlyOption, "Next to discarding the tile, the player can also claim tsumo.");
}

unittest
{
    import std.array;
    auto eventHandler = new TestEventHandler;
    auto player = new Player(eventHandler);
    auto metagame = new Metagame([player]);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d;
    auto factory = constructFactory(tiles, 9, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertNotIn!PromoteToKanOption(factory);
    assertIn!DeclareClosedKanOption(factory);
    assertNotIn!TsumoOption(factory);
    assert(factory.defaultOption.isOfType!DiscardOption, "The discard option should be the default");
    assert(!factory.isDiscardTheOnlyOption, "Next to discarding the tile, the player can also declare a closed kan.");
}
unittest
{
    import std.array;
    auto eventHandler = new TestEventHandler;
    auto player = new Player(eventHandler);
    auto metagame = new Metagame([player]);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀗🀗"d;
    auto openPon = "🀌🀌🀌"d.convertToTiles;
    player.openHand.addPon(openPon);
    auto factory = constructFactory(tiles, 8, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertIn!PromoteToKanOption(factory);
    assertNotIn!DeclareClosedKanOption(factory);
    assertNotIn!TsumoOption(factory);
    assert(factory.defaultOption.isOfType!DiscardOption, "The discard option should be the default");
    assert(!factory.isDiscardTheOnlyOption, "Next to discarding the tile, the player can also upgrade to an open kan.");
}