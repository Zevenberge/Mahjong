module mahjong.domain.set;

import mahjong.domain.enums;
import mahjong.domain.tile;

abstract class Set
{
    this(const Tile[] tiles) pure
    {
        this.tiles = tiles;
    }
    const Tile[] tiles;
    abstract size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const;
    bool isOpen() @property pure const
    {
        import std.algorithm : any;
        return tiles.any!(t => t.isObtainedFromADiscard);
    }
}

bool isPon(const Set s) pure
{
    return cast(PonSet)s !is null;
}

bool isChi(const Set s) pure
{
    return cast(ChiSet)s !is null;
}

bool isPair(const Set s) pure
{
    return cast(PairSet)s !is null;
}

bool isKan(const Set s) pure
{
    return s.isPon && s.tiles.length == 4;
}

bool isSetOf(const Set s, Types type) pure
{
    return s.tiles[0].type == type;
}

@("A set of dragons should be seen as such")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto set = new PonSet("🀄🀄🀄"d.convertToTiles);
    set.isSetOf(Types.dragon).should.equal(true);
    set.isSetOf(Types.wind).should.equal(false);
}

bool isSameAs(const Set one, const Set another)
{
    return one.tiles[0].hasEqualValue(another.tiles[0])
        && typeid(one) == typeid(another);
}

@("Are equal chis the same")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀇🀈🀉"d.convertToTiles);
    first.isSameAs(second).should.equal(true);
    second.isSameAs(first).should.equal(true);
}

@("Are different chis not the same")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀌🀍🀎"d.convertToTiles);
    auto third = new ChiSet("🀐🀑🀒"d.convertToTiles);
    first.isSameAs(second).should.equal(false);
    second.isSameAs(first).should.equal(false);
    first.isSameAs(third).should.equal(false);
    third.isSameAs(first).should.equal(false);
}

@("Are equal pairs the same")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto first = new PairSet("🀙🀙"d.convertToTiles);
    auto second = new PairSet("🀙🀙"d.convertToTiles);
    first.isSameAs(second).should.equal(true);
    second.isSameAs(first).should.equal(true);
}

@("Are different pairs not the same")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto first = new PairSet("🀙🀙"d.convertToTiles);
    auto second = new PairSet("🀐🀐"d.convertToTiles);
    auto third = new PairSet("🀠🀠"d.convertToTiles);
    first.isSameAs(second).should.equal(false);
    second.isSameAs(first).should.equal(false);
    first.isSameAs(third).should.equal(false);
    third.isSameAs(first).should.equal(false);
}

@("Are equal pons the same")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto first = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto second = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto kan = new PonSet("🀙🀙🀙🀙"d.convertToTiles);
    first.isSameAs(second).should.equal(true);
    second.isSameAs(first).should.equal(true);
    first.isSameAs(kan).should.equal(true);
    kan.isSameAs(first).should.equal(true);
}

@("Are different pons not the same")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto first = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto second = new PonSet("🀀🀀🀀"d.convertToTiles);
    first.isSameAs(second).should.equal(false);
    second.isSameAs(first).should.equal(false);
}

@("Are different kind of sets not the same")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto pair = new PairSet("🀙🀙"d.convertToTiles);
    auto pon = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto chi = new ChiSet("🀙🀚🀛"d.convertToTiles);
    pair.isSameAs(pon).should.equal(false);
    pair.isSameAs(chi).should.equal(false);
    pon.isSameAs(chi).should.equal(false);
}

class ThirteenOrphanSet : Set
{
    this(const Tile[] tiles) pure
    {
        super(tiles);
    }

    override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
    {
        return 0;
    }
}

unittest
{
    auto set = new ThirteenOrphanSet(null);
    assert(set.miniPoints(PlayerWinds.east, PlayerWinds.north) == 0, "A thirteen orphan set should have no minipoints whatshowever");
}

class SevenPairsSet : Set
{
    this(const Tile[] tiles) pure
    {
        super(tiles);
    }

    override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
    {
        return 0;
    }
}

unittest
{
    auto set = new SevenPairsSet(null);
    assert(set.miniPoints(PlayerWinds.west, PlayerWinds.east) == 0, "A seven pairs set should have no minipoints whatshowever");
}

class NagashiManganSet : Set
{
    this() pure
    {
        super(null);
    }

    override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
    {
        return 0;
    }
}

class PonSet : Set
{
    this(const Tile[] tiles) pure
    {
        super(tiles);
    }

    override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
    {
        size_t points = 4;
        if(isOpen) points /= 2;
        if(this.isKan) points *= 4;
        if(isSetOfHonoursOrTerminals) points *= 2;
        return points;
    }

    private bool isSetOfHonoursOrTerminals() pure const
    {
        return tiles[0].isHonour || tiles[0].isTerminal;
    }
}

@("Is a pon of simples awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.engine.creation;
    auto normalPon = "🀝🀝🀝"d.convertToTiles;
    auto ponSet = new PonSet(normalPon);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 4, "A closed normal is 4 points");
    normalPon[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 2, "An open normal pon is 2");
}

@("Is a pon of terminals awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.engine.creation;
    auto terminalPon = "🀡🀡🀡"d.convertToTiles;
    auto ponSet = new PonSet(terminalPon);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 8, "A closed terminal is 8 points");
    terminalPon[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 4, "An open terminal pon is 4");
}

@("Is a pon of honours awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.engine.creation;
    auto honourPon = "🀃🀃🀃"d.convertToTiles;
    auto ponSet = new PonSet(honourPon);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 8, "A closed honour is 8 points");
    honourPon[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 4, "An open honour pon is 4");
}

@("Is a kan of simples awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.engine.creation;
    auto normalKan = "🀝🀝🀝🀝"d.convertToTiles;
    auto ponSet = new PonSet(normalKan);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 16, "A closed normal kan is 16 points");
    normalKan[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 8, "An open normal kan is 8");
}

@("Is a kan of terminals awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.engine.creation;
    auto terminalKan = "🀡🀡🀡🀡"d.convertToTiles;
    auto ponSet = new PonSet(terminalKan);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 32, "A closed terminal is 32 points");
    terminalKan[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 16, "An open terminal pon is 16");
}

@("Is a kan of honours awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.engine.creation;
    auto honourKan = "🀃🀃🀃🀃"d.convertToTiles;
    auto ponSet = new PonSet(honourKan);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 32, "A closed honour is 32 points");
    honourKan[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 16, "An open honour pon is 16");
}

class ChiSet : Set
{
    this(const Tile[] tiles) pure
    {
        super(tiles);
    }

    override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
    {
        return 0;
    }
}

@("Is a chi awarded no points")
unittest
{
    auto chiSet = new ChiSet(null);
    assert(chiSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 0, "A chi should give no minipoints whatshowever");
}

class PairSet : Set
{
    this(const Tile[] tiles) pure
    {
        super(tiles);
    }

    override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
    {
        if(tiles[0].type == Types.dragon)
        {
            return 2;
        }
        if(tiles[0].type == Types.wind)
        {
            return tiles[0].value == ownWind || tiles[0].value == leadingWind
                ? 2 
                : 0;
        }
        return 0;
    }
}

@("Is a normal pair awarded no points")
unittest
{
    import mahjong.engine.creation;
    auto normalPair = "🀡🀡"d.convertToTiles;
    auto pairSet = new PairSet(normalPair);
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 0, "A normal pair should have no minipoints");
}

@("Is a pair of winds awarded points if the wind is seat or leading")
unittest
{
    import mahjong.engine.creation;
    auto pairOfNorths = "🀃🀃"d.convertToTiles;
    auto pairSet = new PairSet(pairOfNorths);
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.south) == 0, "A pair of winds that is not leading nor own does not give minipoints");
    assert(pairSet.miniPoints(PlayerWinds.north, PlayerWinds.south) == 2, "If the wind is the own wind, it is 2 points");
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 2, "If the wind is the leading wind, it is 2 points");
}

@("Is a pair of dragons awarded two points")
unittest
{
    import mahjong.engine.creation;
    auto pairOfDragons = "🀄🀄"d.convertToTiles;
    auto pairSet = new PairSet(pairOfDragons);
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 2, "A dragon pair is always 2 points");
}

bool isSameInDifferentType(alias typeCriterion)(const Set one, const Set two, const Set three)
{
    import std.algorithm : isPermutation, all;
    if(one.tiles[0].value == two.tiles[0].value &&
        two.tiles[0].value == three.tiles[0].value)
    {
        return isPermutation([Types.ball, Types.bamboo, Types.character], 
            [one.tiles[0].type, two.tiles[0].type, three.tiles[0].type]) &&
            [one, two, three].all!typeCriterion;
    }
    return false;
}

alias isSameChiInDifferentType = isSameInDifferentType!(s => s.isChi);
alias isSamePonInDifferentType = isSameInDifferentType!(s => s.isPon);

@("Is the same chi in three different types a triplet")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto one = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto two = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto three = new ChiSet("🀜🀝🀞"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(true);
    isSameChiInDifferentType(two, three, one).should.equal(true);
    isSameChiInDifferentType(three, two, one).should.equal(true);
}

@("Are different chis no triplet")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto one = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto two = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto three = new ChiSet("🀟🀠🀡"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(false);
    isSameChiInDifferentType(two, three, one).should.equal(false);
}

@("Are chis in not all three suits no triplet")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto one = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto two = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto three = new ChiSet("🀓🀔🀕"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(false);
}

@("Is a pon not counted in a chi triplet")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto one = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto two = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto three = new PonSet("🀜🀜🀜"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(false);
}
