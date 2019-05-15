module mahjong.ai.data;

import std.algorithm;
import mahjong.domain.set;
import mahjong.domain.tile;

version(mahjong_test)
{
    import std.array;
    import fluent.asserts;
    import mahjong.ai.testing;
}

struct Hand
{
    const Tile[] tiles;
}

auto tilesByType(const Hand hand) pure @nogc nothrow
{
    return hand.tiles.chunkBy!((x,y) => x.type == y.type);
}

@("If I sort my hand by type, I get the correct sets")
unittest
{
    auto h = hand("🀁🀁🀁"d);
    auto result = h.tilesByType.array;
    result.length.should.equal(1);
    result[0].array.length.should.equal(3);
}

@("If I sort my hand by type, different values of the same type are grouped")
unittest
{
    auto h = hand("🀀🀀🀀🀁🀁🀁"d);
    auto result = h.tilesByType.array;
    result.length.should.equal(1);
    result[0].array.length.should.equal(6);
}

@("If I sort my hand by type, different types are in different groups")
unittest
{
    auto h = hand("🀀🀀🀀🀙🀙🀙🀡🀡"d);
    auto result = h.tilesByType.array;
    result.length.should.equal(2);
    result[0].array.length.should.equal(3);
    result[1].array.length.should.equal(5);
}

auto honoursByValue(const Hand hand) pure @nogc nothrow
{
    return hand.tiles.filter!(t => t.isHonour).chunkBy!((x,y) => x.hasEqualValue(y));
}

@("If I have a set of the same honours, I get all honours in one set")
unittest
{
    auto h = hand("🀁🀁🀁"d);
    auto result = h.honoursByValue.array;
    result.length.should.equal(1);
    result[0].array.length.should.equal(3);
}

@("If I have two sets of honours, I get two sets seperated by value")
unittest
{
    auto h = hand("🀀🀀🀀🀁🀁"d);
    auto result = h.honoursByValue.array;
    result.length.should.equal(2);
    result[0].array.length.should.equal(3);
    result[1].array.length.should.equal(2);
}

@("If I have no honours, I get an empty set")
unittest
{
    auto h = hand("🀑🀑🀒🀒🀓🀓🀕"d);
    auto result = h.honoursByValue.array;
    result.length.should.equal(0);
}

auto nonHonoursByType(const Hand hand) pure @nogc nothrow
{
    return hand.tiles.filter!(x => !x.isHonour)
        .chunkBy!((x,y) => x.type == y.type);
}

@("If I have one type of simples, I get one set")
unittest
{
    auto h = hand("🀑🀑🀒🀒🀓🀓🀕"d);
    auto result = h.nonHonoursByType.array;
    result.length.should.equal(1);
    result[0].array.length.should.equal(7);
}

@("If I have two types of simples, I get two sets")
unittest
{
    auto h = hand("🀑🀑🀒🀒🀓🀓🀕🀙🀙🀙"d);
    auto result = h.nonHonoursByType.array;
    result.length.should.equal(2);
    result[0].array.length.should.equal(7);
    result[1].array.length.should.equal(3);
}

@("If I only have honours, I don't get any sets")
unittest
{
    auto h = hand("🀄🀄🀄🀆🀆"d);
    auto result = h.nonHonoursByType.array;
    result.length.should.equal(0);
}

struct Open
{
    const Set[] sets;
}