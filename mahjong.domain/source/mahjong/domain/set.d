module mahjong.domain.set;

import mahjong.domain.enums;
import mahjong.domain.tile;

struct Set
{
    private this(const Tile[] tiles, SetType type) pure @nogc nothrow
    {
        this.tiles = tiles;
        _type = type;
    }
    const Tile[] tiles;
    private SetType _type;
}

Set chi(const Tile[] tiles) pure @nogc nothrow
{
    return Set(tiles, SetType.chi);
}

bool isChi(const Set s) pure @nogc nothrow
{
    return s._type == SetType.chi;
}

@("A chi should be a chi")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto set = chi("🀇🀈🀉"d.convertToTiles);
    set.isChi.should.equal(true);
}

Set pon(const Tile[] tiles) pure @nogc nothrow
{
    return Set(tiles, SetType.pon);
}

bool isPon(const Set s) pure @nogc nothrow
{
    return s._type == SetType.pon;
}

bool isKan(const Set s) pure @nogc nothrow
{
    return s.isPon && s.tiles.length == 4;
}

@("A pon should be a pon but no kan")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto set = pon("🀄🀄🀄"d.convertToTiles);
    set.isPon.should.equal(true);
    set.isKan.should.equal(false);
}

@("A kan should be a pon and kan")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto set = pon("🀄🀄🀄🀄"d.convertToTiles);
    set.isPon.should.equal(true);
    set.isKan.should.equal(true);
}

Set pair(const Tile[] tiles) pure @nogc nothrow
{
    return Set(tiles, SetType.pair);
}

bool isPair(const Set s) pure @nogc nothrow
{
    return s._type == SetType.pair;
}

Set nagashiMangan() pure @nogc nothrow
{
    return Set(null, SetType.nagashiMangan);
}

bool isNagashiMangan(const Set set) pure @nogc nothrow
{
    return set._type == SetType.nagashiMangan;
}

Set sevenPairs(const Tile[] tiles)  pure @nogc nothrow
{
    return Set(tiles, SetType.sevenPairs);
}

bool isSevenPairs(const Set set) pure @nogc nothrow
{
    return set._type == SetType.sevenPairs;
}

Set thirteenOrphans(const Tile[] tiles)  pure @nogc nothrow
{
    return Set(tiles, SetType.thirteenOrphans);
}

bool isThirteenOrphans(const Set set) pure @nogc nothrow
{
    return set._type == SetType.thirteenOrphans;
}

enum SetType
{
    chi, pon, pair, sevenPairs, thirteenOrphans, nagashiMangan
}

bool isOpen(const Set set) @property pure @nogc nothrow
{
    import std.algorithm : any;
    return set.tiles.any!(t => t.isObtainedFromADiscard);
}

bool isSetOf(const Set s, Types type) pure @nogc nothrow
{
    return s.tiles[0].type == type;
}

@("A set of dragons should be seen as such")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto set = pon("🀄🀄🀄"d.convertToTiles);
    set.isSetOf(Types.dragon).should.equal(true);
    set.isSetOf(Types.wind).should.equal(false);
}

bool isSameAs(const Set one, const Set another) pure @nogc nothrow
{
    return one.tiles[0].hasEqualValue(another.tiles[0])
        && one._type == another._type;
}

@("Are equal chis the same")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀇🀈🀉"d.convertToTiles);
    first.isSameAs(second).should.equal(true);
    second.isSameAs(first).should.equal(true);
}

@("Are different chis not the same")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀌🀍🀎"d.convertToTiles);
    auto third = chi("🀐🀑🀒"d.convertToTiles);
    first.isSameAs(second).should.equal(false);
    second.isSameAs(first).should.equal(false);
    first.isSameAs(third).should.equal(false);
    third.isSameAs(first).should.equal(false);
}

@("Are equal pairs the same")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto first = pair("🀙🀙"d.convertToTiles);
    auto second = pair("🀙🀙"d.convertToTiles);
    first.isSameAs(second).should.equal(true);
    second.isSameAs(first).should.equal(true);
}

@("Are different pairs not the same")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto first = pair("🀙🀙"d.convertToTiles);
    auto second = pair("🀐🀐"d.convertToTiles);
    auto third = pair("🀠🀠"d.convertToTiles);
    first.isSameAs(second).should.equal(false);
    second.isSameAs(first).should.equal(false);
    first.isSameAs(third).should.equal(false);
    third.isSameAs(first).should.equal(false);
}

@("Are equal pons the same")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto first = pon("🀙🀙🀙"d.convertToTiles);
    auto second = pon("🀙🀙🀙"d.convertToTiles);
    auto kan = pon("🀙🀙🀙🀙"d.convertToTiles);
    first.isSameAs(second).should.equal(true);
    second.isSameAs(first).should.equal(true);
    first.isSameAs(kan).should.equal(true);
    kan.isSameAs(first).should.equal(true);
}

@("Are different pons not the same")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto first = pon("🀙🀙🀙"d.convertToTiles);
    auto second = pon("🀀🀀🀀"d.convertToTiles);
    first.isSameAs(second).should.equal(false);
    second.isSameAs(first).should.equal(false);
}

@("Are different kind of sets not the same")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pair = .pair("🀙🀙"d.convertToTiles);
    auto pon = .pon("🀙🀙🀙"d.convertToTiles);
    auto chi = .chi("🀙🀚🀛"d.convertToTiles);
    pair.isSameAs(pon).should.equal(false);
    pair.isSameAs(chi).should.equal(false);
    pon.isSameAs(chi).should.equal(false);
}

size_t miniPoints(const Set set, PlayerWinds ownWind, PlayerWinds leadingWind) pure @nogc nothrow
{
    final switch(set._type)
    {
        case SetType.chi:
        case SetType.sevenPairs:
        case SetType.thirteenOrphans:
        case SetType.nagashiMangan:
            return 0;
        case SetType.pon:
            size_t points = 4;
            if(set.isOpen) points /= 2;
            if(set.isKan) points *= 4;
            if(set.tiles[0].isHonourOrTerminal) points *= 2;
            return points;
        case SetType.pair:
            if(set.tiles[0].type == Types.dragon) return 2;
            if(set.tiles[0].type == Types.wind)
            {
                return set.tiles[0].value == ownWind || set.tiles[0].value == leadingWind
                    ? 2 : 0;
            }
            return 0;

    }
}

@("A thirteen orphans set doesn't give any minipoints")
unittest
{
    auto set = thirteenOrphans(null);
    assert(set.miniPoints(PlayerWinds.east, PlayerWinds.north) == 0);
}

@("A seven pairs set doesn't give any minipoints")
unittest
{
    auto set = sevenPairs(null);
    assert(set.miniPoints(PlayerWinds.west, PlayerWinds.east) == 0);
}

@("Is a pon of simples awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.creation;
    auto normalPon = "🀝🀝🀝"d.convertToTiles;
    auto ponSet = pon(normalPon);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 4, "A closed normal is 4 points");
    normalPon[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 2, "An open normal pon is 2");
}

@("Is a pon of terminals awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.creation;
    auto terminalPon = "🀡🀡🀡"d.convertToTiles;
    auto ponSet = pon(terminalPon);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 8, "A closed terminal is 8 points");
    terminalPon[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 4, "An open terminal pon is 4");
}

@("Is a pon of honours awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.creation;
    auto honourPon = "🀃🀃🀃"d.convertToTiles;
    auto ponSet = pon(honourPon);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 8, "A closed honour is 8 points");
    honourPon[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 4, "An open honour pon is 4");
}

@("Is a kan of simples awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.creation;
    auto normalKan = "🀝🀝🀝🀝"d.convertToTiles;
    auto ponSet = pon(normalKan);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 16, "A closed normal kan is 16 points");
    normalKan[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 8, "An open normal kan is 8");
}

@("Is a kan of terminals awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.creation;
    auto terminalKan = "🀡🀡🀡🀡"d.convertToTiles;
    auto ponSet = pon(terminalKan);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 32, "A closed terminal is 32 points");
    terminalKan[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 16, "An open terminal pon is 16");
}

@("Is a kan of honours awarded correct points")
unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.creation;
    auto honourKan = "🀃🀃🀃🀃"d.convertToTiles;
    auto ponSet = pon(honourKan);
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 32, "A closed honour is 32 points");
    honourKan[0].isDiscarded;
    assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 16, "An open honour pon is 16");
}

@("Is a normal pair awarded no points")
unittest
{
    import mahjong.domain.creation;
    auto normalPair = "🀡🀡"d.convertToTiles;
    auto pairSet = pair(normalPair);
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 0, "A normal pair should have no minipoints");
}

@("Is a pair of winds awarded points if the wind is seat or leading")
unittest
{
    import mahjong.domain.creation;
    auto pairOfNorths = "🀃🀃"d.convertToTiles;
    auto pairSet = pair(pairOfNorths);
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.south) == 0, "A pair of winds that is not leading nor own does not give minipoints");
    assert(pairSet.miniPoints(PlayerWinds.north, PlayerWinds.south) == 2, "If the wind is the own wind, it is 2 points");
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 2, "If the wind is the leading wind, it is 2 points");
}

@("Is a pair of dragons awarded two points")
unittest
{
    import mahjong.domain.creation;
    auto pairOfDragons = "🀄🀄"d.convertToTiles;
    auto pairSet = pair(pairOfDragons);
    assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 2, "A dragon pair is always 2 points");
}

@("Is a chi awarded no points")
unittest
{
    auto chiSet = chi(null);
    assert(chiSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 0, "A chi should give no minipoints whatshowever");
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
    import mahjong.domain.creation;
    auto one = chi("🀊🀋🀌"d.convertToTiles);
    auto two = chi("🀓🀔🀕"d.convertToTiles);
    auto three = chi("🀜🀝🀞"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(true);
    isSameChiInDifferentType(two, three, one).should.equal(true);
    isSameChiInDifferentType(three, two, one).should.equal(true);
}

@("Are different chis no triplet")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto one = chi("🀊🀋🀌"d.convertToTiles);
    auto two = chi("🀓🀔🀕"d.convertToTiles);
    auto three = chi("🀟🀠🀡"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(false);
    isSameChiInDifferentType(two, three, one).should.equal(false);
}

@("Are chis in not all three suits no triplet")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto one = chi("🀊🀋🀌"d.convertToTiles);
    auto two = chi("🀓🀔🀕"d.convertToTiles);
    auto three = chi("🀓🀔🀕"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(false);
}

@("Is a pon not counted in a chi triplet")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto one = chi("🀊🀋🀌"d.convertToTiles);
    auto two = chi("🀓🀔🀕"d.convertToTiles);
    auto three = pon("🀜🀜🀜"d.convertToTiles);
    isSameChiInDifferentType(one, two, three).should.equal(false);
}
