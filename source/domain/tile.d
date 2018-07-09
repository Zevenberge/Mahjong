module mahjong.domain.tile;

import std.conv;
import std.math;
import std.uuid;

import mahjong.domain.enums;
import mahjong.domain.ingame;

class Tile
{ 
    dchar face; // The unicode face of the tile. 
    const ComparativeTile _;
    alias _ this;
    const UUID id;

    int dora = 0;
    Ingame origin = null;
    bool isOwn() @property pure const
    {
        return origin is null;
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
        return(to!string(face));
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

struct ComparativeTile
{
    Types type;
    int value;

    bool hasEqualValue(const ComparativeTile other) pure const
    {
        return other.type == type && other.value == value;
    }
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
