module mahjong.graphics.controllers.game.turnoption;

import std.algorithm;
import std.array;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.menu.menuitem;
import mahjong.util.range;

alias TurnOptionController = IngameOptionsController!(TurnOptionFactory, "");

class TurnOptionFactory
{
    this(const Tile selectedTile, 
        TurnEvent turnEvent, bool canCancel)
    {
        auto player = turnEvent.player;
        auto metagame = turnEvent.metagame;
        addTsumoOption(player, turnEvent);
        addRiichiOption(metagame, player, selectedTile, turnEvent);
        addPromoteToKanOption(player, selectedTile, turnEvent);
        addDeclareClosedKanOption(player, selectedTile, turnEvent);
        addDeclareRedrawOption(player, metagame, turnEvent);
        addDiscardOption(selectedTile, turnEvent);
        _isDiscardTheOnlyOption = _options.length == 1;
        if(canCancel) addCancelOption;
    }

    private void addTsumoOption(const Player player, TurnEvent turnEvent)
    {
        if(!player.canTsumo(turnEvent.metagame)) return;
        auto tsumoOption = new TsumoOption(player, turnEvent);
        _options ~= tsumoOption;
        _defaultOption = tsumoOption;
    }

    private void addRiichiOption(const Metagame metagame, const Player player, 
        const Tile selectedTile, TurnEvent turnEvent)
    {
        if(!player.canDeclareRiichi(selectedTile, metagame)) return;
        auto riichiOption = new RiichiOption(selectedTile, turnEvent);
        _options ~= riichiOption;
        if(!_defaultOption) _defaultOption = riichiOption;
    }

    private void addPromoteToKanOption(const Player player, 
        const Tile selectedTile, TurnEvent turnEvent)
    {
        if(!player.canPromoteToKan(selectedTile)) return;
        _options ~= new PromoteToKanOption(player, selectedTile, turnEvent);
    }

    private void addDeclareClosedKanOption(const Player player, 
        const Tile selectedTile, TurnEvent turnEvent)
    {
        if(!player.canDeclareClosedKan(selectedTile)) return;
        _options ~= new DeclareClosedKanOption(player, selectedTile, turnEvent);
    }

    private void addDeclareRedrawOption(const Player player, 
        const Metagame metagame, TurnEvent turnEvent)
    {
        if(!player.isEligibleForRedraw(metagame)) return;
        _options ~= new DeclareRedrawOption(turnEvent);
    }

    private void addDiscardOption(const Tile selectedTile, TurnEvent turnEvent)
    {
        auto discardOption = new DiscardOption(selectedTile, turnEvent);
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

version(unittest)
{
    import std.algorithm;
    import std.stdio;
    import std.string;
    import mahjong.domain.creation;
    import mahjong.engine;
    import mahjong.engine.flow;
    import mahjong.engine.notifications;
    void assertIn(T)(TurnOptionFactory factory)
    {
        assert(factory.options.any!(co => cast(T)co), 
            "TurnOption %s not found.".format(T.stringof));
    }
    void assertNotIn(T)(TurnOptionFactory factory)
    {
        assert(factory.options.all!(co => !cast(T)co), 
            "TurnOption %s found when it should not.".format(T.stringof));
    }
    TurnOptionFactory constructFactory(dstring tilesOfTurnPlayer, size_t indexOfDiscard, 
        Player player, Metagame metagame, bool canCancel = true)
    {
        player.closedHand.tiles = tilesOfTurnPlayer.convertToTiles;
        foreach(tile; player.closedHand.tiles) 
        {
            tile.isDrawnBy(player);
        }
        auto selectedTile = player.closedHand.tiles[indexOfDiscard];
        auto engine = new Engine(metagame);
        writeln("Selecting ", selectedTile);
        return new TurnOptionFactory(selectedTile,
            new TurnEvent(metagame, player, selectedTile), canCancel);
    }
}

@("When all other fails, the discard and cancel options are still present")
unittest
{
    import std.array;
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player = new Player();
    auto metagame = new Metagame([player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀀🀀🀄🀄🀄🀆🀆🀇🀇🀏🀕🀕🀚🀚"d;
    auto factory = constructFactory(tiles, 13, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertNotIn!PromoteToKanOption(factory);
    assertNotIn!DeclareClosedKanOption(factory);
    assertNotIn!TsumoOption(factory);
    assertNotIn!RiichiOption(factory);
    assertNotIn!DeclareRedrawOption(factory);
    factory.defaultOption.should.be.instanceOf!DiscardOption;
    factory.isDiscardTheOnlyOption.should.equal(true);
}

@("When being mahjong with a closed hand, one can tsumo and declare riichi")
unittest
{
    import std.array;
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player = new Player();
    auto metagame = new Metagame([player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d;
    auto factory = constructFactory(tiles, 0, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertNotIn!PromoteToKanOption(factory);
    assertNotIn!DeclareClosedKanOption(factory);
    assertIn!TsumoOption(factory);
    assertIn!RiichiOption(factory);
    factory.defaultOption.should.be.instanceOf!TsumoOption;
    factory.isDiscardTheOnlyOption.should.equal(false);
}

unittest
{
    import std.array;
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player = new Player();
    auto metagame = new Metagame([player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d;
    auto factory = constructFactory(tiles, 9, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertNotIn!PromoteToKanOption(factory);
    assertIn!DeclareClosedKanOption(factory);
    assertNotIn!TsumoOption(factory);
    assertNotIn!RiichiOption(factory);
    factory.defaultOption.should.be.instanceOf!DiscardOption;
    factory.isDiscardTheOnlyOption.should.equal(false);
}

unittest
{
    import std.array;
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player = new Player();
    auto metagame = new Metagame([player], new DefaultGameOpts);
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
    assertNotIn!RiichiOption(factory);
    factory.defaultOption.should.be.instanceOf!DiscardOption;
    factory.isDiscardTheOnlyOption.should.equal(false);
}

unittest
{
    import std.array;
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player = new Player();
    auto metagame = new Metagame([player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀀🀁🀂🀃🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d;
    auto factory = constructFactory(tiles, 5, player, metagame);
    assertIn!CancelOption(factory);
    assertIn!DiscardOption(factory);
    assertNotIn!PromoteToKanOption(factory);
    assertNotIn!DeclareClosedKanOption(factory);
    assertNotIn!TsumoOption(factory);
    assertIn!RiichiOption(factory);
    factory.defaultOption.should.be.instanceOf!RiichiOption;
    factory.isDiscardTheOnlyOption.should.equal(false);
}

@("If cancel is no option, it should not be included")
unittest
{
    import std.array;
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player = new Player();
    auto metagame = new Metagame([player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d;
    auto factory = constructFactory(tiles, 0, player, metagame, false);
    assertNotIn!CancelOption(factory);
}

@("An option to declare a redraw should be included if relevant")
unittest
{
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player = new Player();
    auto metagame = new Metagame([player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto tiles = "🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d;
    auto factory = constructFactory(tiles, 0, player, metagame, false);
    assertIn!DeclareRedrawOption(factory);
}

class TurnOption : MenuItem, IRelevantTiles
{
    this(string displayName)
    {
        import mahjong.graphics.opts;
        super(displayName, styleOpts);
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
    this(const Player player, const Tile selectedTile, TurnEvent event)
    {
        super("Kan");
        _player = player;
        _selectedTile = selectedTile;
        _event = event;
    }

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
    this(const Player player, const Tile selectedTile, TurnEvent event)
    {
        super("Kan");
        _player = player;
        _selectedTile = selectedTile;
        _event = event;
    }

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
    this(const Player player, TurnEvent event)
    {
        super("Tsumo");
        _player = player;
        _event = event;
    }

    private const Player _player;
    private TurnEvent _event;

    protected override void apply() 
    {
        _event.claimTsumo;
    }

    override const(Tile)[] relevantTiles() @property
    {
        return _player.closedHand.tiles ~ _player.openHand.tiles.array;
    }
}

class RiichiOption : AssertiveTurnOption
{
    this(const Tile selectedTile, TurnEvent event)
    {
        super("Riichi");
        _selectedTile = selectedTile;
        _event = event;
    }

    private const Tile _selectedTile;
    private TurnEvent _event;

    protected override void apply() 
    {
        _event.declareRiichi(_selectedTile);
    }

    override const(Tile)[] relevantTiles() 
    {
        return _event.player.closedHand.tiles.without([_selectedTile]);
    }
}

class DeclareRedrawOption : AssertiveTurnOption
{
    this(TurnEvent event)
    {
        super("Redraw");
        _event = event;
    }

    private TurnEvent _event;

    protected override void apply() 
    {
        _event.declareRedraw;
    }

    override const(Tile)[] relevantTiles() 
    {
        return null;
    }
}

class DiscardOption : AssertiveTurnOption
{
    this(const Tile selectedTile, TurnEvent event)
    {
        super("Discard");
        _selectedTile = selectedTile;
        _event = event;
    }

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
