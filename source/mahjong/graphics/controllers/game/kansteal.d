module mahjong.graphics.controllers.game.kansteal;

import mahjong.domain.tile;
import mahjong.engine.flow;
import mahjong.graphics.controllers.game;
import mahjong.graphics.menu.menuitem;

alias KanStealOptionController = IngameOptionsController!(KanStealOptionsFactory, "");

class KanStealOptionsFactory
{
    this(KanStealEvent event)
    in
    {
        assert(event.canSteal, "The factory should only be created when the tile can be robbed");
    }
    do
    {
        _options = [
            new StealOption(event.player.closedHand.tiles ~ event.kanTile, event),
            new PassOption(event)
        ];
    }

    private KanStealOption[] _options;
    KanStealOption[] options()
    {
        return _options;
    }

    KanStealOption defaultOption()
    {
        return _options[0];
    }
}

@("The factory provides two options")
unittest
{
    import fluent.asserts;
    import mahjong.domain.enums;
    import mahjong.domain.player;
    import mahjong.domain.metagame;
    import mahjong.engine.opts;
    auto tile = new Tile(Types.wind, Winds.east);
    auto player = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
    auto metagame = new Metagame([player], new DefaultGameOpts);
    auto event = new KanStealEvent(tile, player, metagame);
    auto factory = new KanStealOptionsFactory(event);
    factory.options.length.should.equal(2);
    factory.defaultOption.should.be.instanceOf!StealOption;
}

abstract class KanStealOption : MenuItem, IRelevantTiles
{
    this(string displayName, const(Tile)[] relevantTiles)
    {
        super(displayName);
        _relevantTiles = relevantTiles;
    }

    private const(Tile)[] _relevantTiles;
    const(Tile)[] relevantTiles() @property pure const 
    {
        return _relevantTiles;
    }
}

final class StealOption : KanStealOption
{
    this(const(Tile)[] relevantTiles, KanStealEvent event)
    {
        super("Steal", relevantTiles);
        _event = event;
    }

    private KanStealEvent _event;

    final override void select()
    {
        _event.steal;
    }
}

final class PassOption : KanStealOption
{
    this(KanStealEvent event)
    {
        super("Pass", null);
        _event = event;
    }

    private KanStealEvent _event;

    final override void select()
    {
        _event.pass;
    }
}