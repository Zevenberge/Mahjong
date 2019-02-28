module mahjong.domain.tile;

import std.conv;
import std.math;
import std.uuid;

import mahjong.domain.enums;
import mahjong.domain.ingame;

class Tile
{ 
    const ComparativeTile _;
    alias _ this;
    const UUID id;

    int dora = 0;
    Ingame origin = null;
    bool isOwn() @property pure const
    {
        return origin is null;
    }

    version(unittest)
    {
        void isNotOwn()
        {
            origin = new Ingame(PlayerWinds.autumn);
        }
    }
    
    this(Types type, int value)
    {
        id = randomUUID;
        this._ = ComparativeTile(type, value);
    }

    void close() 
    {
        _isOpen = false;
    }
    
    void open() 
    {
        _isOpen = true;
    }

    private bool _isOpen = false;
    bool isOpen() @property pure const
    {
        return _isOpen;
    }

    override string toString() const
    {
        import std.format;
        return format!"%s-%s"(type, value);
    }
    
    bool isIdentical(const Tile other) pure const
    {
        return id == other.id;
    }

    void claim()
    {
        origin.discardIsClaimed(this);
    }
}

unittest
{
    auto tile = new Tile(Types.wind, 4);
    assert(tile.isIdentical(tile), "Tile was not identical with itself");
    auto anotherTile = new Tile(Types.wind, 4);
    assert(!tile.isIdentical(anotherTile), "Tile was a different tile");
}

bool isHonour(const ComparativeTile tile) @property pure
{
    return tile.type < Types.character;
}

unittest
{
    auto tile = new Tile(Types.wind, 1);
    assert(tile.isHonour, "Tile should have been an honour");
    tile = new Tile(Types.dragon, 1);
    assert(tile.isHonour, "Tile should have been an honour");
    tile = new Tile(Types.character, 1);
    assert(!tile.isHonour, "Tile should not have been an honour");
    tile = new Tile(Types.bamboo, 1);
    assert(!tile.isHonour, "Tile should not have been an honour");
    tile = new Tile(Types.ball, 1);
    assert(!tile.isHonour, "Tile should not have been an honour");
}

bool isTerminal(const ComparativeTile tile) @property pure
{
    return !tile.isHonour && (tile.value == Numbers.one || tile.value == Numbers.nine);
}

unittest
{
    auto tile = new Tile(Types.character, Numbers.one);
    assert(tile.isTerminal, "Tile should have been a terminal");
    tile = new Tile(Types.character, Numbers.two);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.character, Numbers.three);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.character, Numbers.four);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.character, Numbers.five);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.character, Numbers.six);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.character, Numbers.seven);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.character, Numbers.eight);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.character, Numbers.nine);
    assert(tile.isTerminal, "Tile should have been a terminal");
    tile = new Tile(Types.wind, Winds.east);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
    tile = new Tile(Types.dragon, Dragons.green);
    assert(!tile.isTerminal, "Tile should not have been a terminal");
}

unittest
{
    auto tileA = new Tile(Types.dragon, Dragons.green);
    auto tileB = new Tile(Types.dragon, Dragons.green);
    assert(tileA.hasEqualValue(tileB), "Equal tiles were not seen as equal");
    tileB = new Tile(Types.dragon, Dragons.red);
    assert(!tileA.hasEqualValue(tileB), "Non equal tiles were equal");
    tileB = new Tile(Types.wind, Dragons.red);
    assert(!tileA.hasEqualValue(tileB), "Non equal tiles were equal");
    tileB = new Tile(Types.wind, Dragons.green);
    assert(!tileA.hasEqualValue(tileB), "Non equal tiles were equal");
}

bool isHonourOrTerminal(const ComparativeTile tile)
{
    return tile.isHonour || tile.isTerminal;
}

bool isSimple(const ComparativeTile tile)
{
    return !tile.isHonourOrTerminal;
}

bool isConstructive(const ComparativeTile first, const ComparativeTile other) pure
{
    return !first.isHonour && first.type == other.type &&
        abs(first.value - other.value) == 1;
}

unittest
{
    import std.stdio;
    writeln("Checking the isConstructive function...");
    auto one = new Tile(Types.bamboo, 1);
    auto two = new Tile(Types.bamboo, 2);
    assert(one.isConstructive(two));
    assert(two.isConstructive(one));
    auto three = new Tile(Types.bamboo, 3);
    assert(!one.isConstructive(three));
    auto otherTwo = new Tile(Types.ball, 2);
    assert(!one.isConstructive(otherTwo));
    writeln(" The isConstructive function is correct.");
}

bool isWind(const ComparativeTile tile) @property pure
{
    return tile.type == Types.wind;
}

unittest
{
    import fluent.asserts;
    auto wind = ComparativeTile(Types.wind, Winds.west);
    wind.isWind.should.equal(true);
    auto dragon = ComparativeTile(Types.dragon, Dragons.white);
    dragon.isWind.should.equal(false);
}

bool isGreen(const ComparativeTile tile) @property pure
{
    static immutable theGreens = [
        ComparativeTile(Types.dragon, Dragons.green),
        ComparativeTile(Types.bamboo, Numbers.two),
        ComparativeTile(Types.bamboo, Numbers.three),
        ComparativeTile(Types.bamboo, Numbers.four),
        ComparativeTile(Types.bamboo, Numbers.six),
        ComparativeTile(Types.bamboo, Numbers.eight)];
    static foreach(greenTile; theGreens)
    {
        if(greenTile == tile) return true;
    }
    return false;
}

@("Are green tiles green")
unittest
{
    import fluent.asserts;
    auto greenDragon = ComparativeTile(Types.dragon, Dragons.green);
    greenDragon.isGreen.should.equal(true);
    auto bambooTwo = ComparativeTile(Types.bamboo, Numbers.two);
    bambooTwo.isGreen.should.equal(true);
    auto bambooThree = ComparativeTile(Types.bamboo, Numbers.three);
    bambooThree.isGreen.should.equal(true);
    auto bambooFour = ComparativeTile(Types.bamboo, Numbers.four);
    bambooFour.isGreen.should.equal(true);
    auto bambooSix = ComparativeTile(Types.bamboo, Numbers.six);
    bambooSix.isGreen.should.equal(true);
    auto bambooEight = ComparativeTile(Types.bamboo, Numbers.eight);
    bambooEight.isGreen.should.equal(true);
}

@("Are not green tiles not green")
unittest
{
    import fluent.asserts;
    auto redDragon = ComparativeTile(Types.dragon, Dragons.red);
    redDragon.isGreen.should.equal(false);
    auto bambooOne = ComparativeTile(Types.bamboo, Numbers.one);
    bambooOne.isGreen.should.equal(false);
    auto bambooFive = ComparativeTile(Types.bamboo, Numbers.five);
    bambooFive.isGreen.should.equal(false);
    auto bambooSeven = ComparativeTile(Types.bamboo, Numbers.seven);
    bambooSeven.isGreen.should.equal(false);
    auto characterTwo = ComparativeTile(Types.character, Numbers.two);
    characterTwo.isGreen.should.equal(false);
}

bool isDora(const Tile tile) @property pure
{
    return tile.dora > 0;
}

struct ComparativeTile
{
    Types type;
    int value;
}

bool hasEqualValue(const ComparativeTile one, const ComparativeTile other) pure
{
    return one == other;
}

unittest
{
    auto tile = new Tile(Types.dragon, Dragons.green);
    auto comparativeTile = ComparativeTile(Types.dragon, Dragons.green);
    assert(comparativeTile.hasEqualValue(tile), "Comparative tile should have an equal value");
}
unittest
{
    auto tile = new Tile(Types.dragon, Dragons.red);
    auto comparativeTile = ComparativeTile(Types.dragon, Dragons.green);
    assert(!comparativeTile.hasEqualValue(tile), "Comparative tile should not have an equal value");
}
unittest
{
    auto tile = new Tile(Types.wind, Dragons.green);
    auto comparativeTile = ComparativeTile(Types.dragon, Dragons.green);
    assert(!comparativeTile.hasEqualValue(tile), "Comparative tile should not have an equal value");
}

// HACK this should be configured somewhere else.
version(unittest)
{
    static this()
    {
        import std.experimental.logger;
        sharedLog.logLevel = LogLevel.warning;
    }
}

template isRangeOfTiles(Range)
{
    import std.range;
    enum isRangeOfTiles = isInputRange!Range && is(ElementType!Range : ComparativeTile);
}

unittest
{
    import fluent.asserts;
    isRangeOfTiles!(ComparativeTile[]).should.equal(true);
    isRangeOfTiles!(Tile[]).should.equal(true);
    isRangeOfTiles!(PlayerWinds[]).should.equal(false);
    isRangeOfTiles!Tile.should.equal(false);
}

bool isAllSimples(Range)(Range range)
    if(isRangeOfTiles!Range)
{
    import std.algorithm : all;
    return range.all!(t => t.isSimple);
}

@("All simples should be true")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.eight), 
        ComparativeTile(Types.bamboo, Numbers.six),
        ComparativeTile(Types.character, Numbers.two)]
        .isAllSimples.should.equal(true);
}

@("All simples should be false")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.one)]
    .isAllSimples.should.equal(false);
    [ComparativeTile(Types.wind, Winds.south)]
    .isAllSimples.should.equal(false);
}

bool isAllOfSameSuit(Range)(Range range)
    if(isRangeOfTiles!Range)
{
    import optional;
    Optional!Types type = no!Types;
    foreach(tile; range)
    {
        if(tile.isHonour) return false;
        if(type == none)
        {
            type = some(tile.type);
        }
        else
        {
            if(type != tile.type) return false;
        }
    }
    return true;
}

@("All of the same suit should return true for simple types")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.eight), ComparativeTile(Types.ball, Numbers.nine)]
    .isAllOfSameSuit.should.equal(true);
    [ComparativeTile(Types.bamboo, Numbers.eight), ComparativeTile(Types.bamboo, Numbers.nine)]
    .isAllOfSameSuit.should.equal(true);
    [ComparativeTile(Types.character, Numbers.eight), ComparativeTile(Types.character, Numbers.nine)]
    .isAllOfSameSuit.should.equal(true);
}

@("All of the same suit should return false for different suits or honours")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.eight), ComparativeTile(Types.bamboo, Numbers.nine)]
    .isAllOfSameSuit.should.equal(false);
    [ComparativeTile(Types.wind, Winds.east), ComparativeTile(Types.wind, Winds.east)]
    .isAllOfSameSuit.should.equal(false);
}

bool isHalfFlush(Range)(Range range)
    if(isRangeOfTiles!Range)
{
    import optional;
    Optional!Types type = no!Types;
    bool hasHonour;
    foreach(tile; range)
    {
        if(tile.isHonour)
        {
            hasHonour = true;
            continue;
        }
        if(type == none)
        {
            type = some(tile.type);
        }
        else
        {
            if(type != tile.type) return false;
        }
    }
    return hasHonour && type != none;
}

@("Is half flush should return true if both honours and one suit")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.dragon, Dragons.green), 
        ComparativeTile(Types.bamboo, Numbers.eight),
        ComparativeTile(Types.bamboo, Numbers.eight)]
        .isHalfFlush.should.equal(true);
    [ComparativeTile(Types.dragon, Dragons.green), 
        ComparativeTile(Types.ball, Numbers.eight)]
        .isHalfFlush.should.equal(true);
    [ComparativeTile(Types.dragon, Dragons.green), 
        ComparativeTile(Types.character, Numbers.eight)]
        .isHalfFlush.should.equal(true);
}

@("A honour and different suits is no half flush")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.dragon, Dragons.green), 
        ComparativeTile(Types.bamboo, Numbers.eight),
        ComparativeTile(Types.ball, Numbers.eight)]
        .isHalfFlush.should.equal(false);
}

@("A honour is required for a half flush")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.bamboo, Numbers.eight), 
        ComparativeTile(Types.bamboo, Numbers.eight),
        ComparativeTile(Types.bamboo, Numbers.eight)]
        .isHalfFlush.should.equal(false);
}

@("Only honours is no half flush")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.dragon, Dragons.green), 
        ComparativeTile(Types.dragon, Dragons.green)]
        .isHalfFlush.should.equal(false);
}

bool isAllHonourOrTerminal(Range)(Range range)
    if(isRangeOfTiles!Range)
{
    import std.algorithm : all;
    return range.all!(t => t.isHonourOrTerminal);
}

@("Is all honours and terminal recognised")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.dragon, Dragons.green),
        ComparativeTile(Types.character, Numbers.one)]
        .isAllHonourOrTerminal.should.equal(true);
    [ComparativeTile(Types.dragon, Dragons.green),
        ComparativeTile(Types.wind, Winds.east)]
        .isAllHonourOrTerminal.should.equal(true);
    [ComparativeTile(Types.character, Numbers.one),
        ComparativeTile(Types.bamboo, Numbers.nine)]
        .isAllHonourOrTerminal.should.equal(true);
}

@("Non terminals make the set non all honours or terminals")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.two)]
        .isAllHonourOrTerminal.should.equal(false);
}

bool isAllHonour(Range)(Range range)
    if(isRangeOfTiles!Range)
{
    import std.algorithm : all;
    return range.all!(t => t.isHonour);
}

@("Is all honours recognised")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.dragon, Dragons.green),
        ComparativeTile(Types.wind, Winds.east)]
        .isAllHonour.should.equal(true);
}

@("Non honours make the set not have only honours")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.one)]
        .isAllHonour.should.equal(false);
}

bool isAllTerminal(Range)(Range range)
    if(isRangeOfTiles!Range)
{
    import std.algorithm : all;
    return range.all!(t => t.isTerminal);
}

@("Is all terminals recognised")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.bamboo, Numbers.one),
        ComparativeTile(Types.character, Numbers.nine)]
        .isAllTerminal.should.equal(true);
}

@("Non terminals make the set not have only terminals")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.wind, Winds.east)]
        .isAllTerminal.should.equal(false);
}

bool hasTerminal(Range)(Range range)
    if(isRangeOfTiles!Range)
{
    import std.algorithm : any;
    return range.any!(t => t.isTerminal);
}

@("A range with at least one terminal has a terminal")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.one), 
        ComparativeTile(Types.ball, Numbers.one),
        ComparativeTile(Types.ball, Numbers.one)]
        .hasTerminal.should.equal(true);
    [ComparativeTile(Types.ball, Numbers.one), 
        ComparativeTile(Types.ball, Numbers.two),
        ComparativeTile(Types.ball, Numbers.three)]
        .hasTerminal.should.equal(true);
    [ComparativeTile(Types.ball, Numbers.seven), 
        ComparativeTile(Types.ball, Numbers.eight),
        ComparativeTile(Types.ball, Numbers.nine)]
        .hasTerminal.should.equal(true);
}

@("A range with only simples has no terminal")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.ball, Numbers.four), 
        ComparativeTile(Types.ball, Numbers.five),
        ComparativeTile(Types.ball, Numbers.six)]
        .hasTerminal.should.equal(false);
}

@("Honours are no terminals")
unittest
{
    import fluent.asserts;
    [ComparativeTile(Types.wind, Winds.east), 
        ComparativeTile(Types.wind, Winds.east),
        ComparativeTile(Types.wind, Winds.east)]
        .hasTerminal.should.equal(false);
}

bool isAllGreens(Range)(Range range) pure
    if(isRangeOfTiles!Range)
{
    import std.algorithm : all;
    return range.all!(t => t.isGreen);
}

@("Is all greens recognised")
unittest
{
    import fluent.asserts;
    auto greens = [ComparativeTile(Types.dragon, Dragons.green),
        ComparativeTile(Types.bamboo, Numbers.two)];
    greens.isAllGreens.should.equal(true);
}

@("Does not all greens not give a false positive")
unittest
{
    import fluent.asserts;
    auto greens = [ComparativeTile(Types.dragon, Dragons.red),
        ComparativeTile(Types.bamboo, Numbers.two)];
    greens.isAllGreens.should.equal(false);
}

