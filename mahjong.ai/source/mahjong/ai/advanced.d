module mahjong.ai.advanced;

import std.algorithm;
import std.array;
import std.meta;
import std.typecons;
import optional.optional;
import mahjong.ai;
import mahjong.ai.data;
import mahjong.ai.decision;
import mahjong.domain.analysis;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.util.collections;

alias Hand = mahjong.ai.data.Hand;

version(mahjong_ai_test)
{
    import fluent.asserts;
    import mahjong.ai.testing;
}

/+class AdvancedAI : AI
{

}+/

TurnDecision discardUnrelatedTile(const Hand hand, const Player player) pure @nogc nothrow
{
    Rebindable!(const Tile) tile;
    static foreach(check; AliasSeq!(
        selectOnlyTileOfType,
        selectLonelyHonour,
        selectUnconnectedTerminal,
        selectUnconnectedTile,
        selectTileNotConnectedFromSet
        ))
    {
        tile = check(hand);
        if(tile) return discard(tile, player);
    }
    return discard(hand.tiles[0], player);
}

@("Discarding an unrelated tile always decides a discard")
unittest
{
    auto result = discardUnrelatedTile(hand("🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d), player);
    result.action.should.equal(TurnDecision.Action.discard);
}

@("The decision should include the player it was made for")
unittest
{
    auto p = player;
    auto result = discardUnrelatedTile(hand("🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d), p);
    result.player.should.equal(p);
}

@("If I have a lonely wind, then I discard it")
unittest
{
    auto h = hand("🀁🀇🀈🀉🀊🀋🀌🀍🀎🀏🀙🀜🀝🀡"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[0]);
}

@("If I have a lonely character, then I discard it")
unittest
{
    auto h = hand("🀁🀁🀆🀆🀆🀑🀑🀓🀕🀇🀙🀜🀝🀡"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[9]);
}

@("If I cannot determine any result, there should still be a discard")
unittest
{
    auto result = discardUnrelatedTile(hand("🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀"d), player);
    result.selectedTile.should.not.beNull;
}

@("If I have a standalone tile, I want to discard that one")
unittest
{
    auto h = hand("🀁🀁🀃🀆🀆🀑🀑🀓🀕🀙🀙🀜🀝🀡"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[2]);
}

@("If I have an unconnected terminal, I want to discard it")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀔🀕🀘🀙🀙🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[8]);
}

@("If I have an unconnected starting terminal, I want to discard it")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀔🀕🀘🀘🀙🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[10]);
}

@("If I have an unconnected simple, I want to discard it")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀔🀕🀘🀘🀘🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[11]);
}

@("If I have an unconnected simple, I want to discard it even if it's the last one")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀔🀕🀘🀘🀘🀜🀜🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[13]);
}

@("If I have an unconnected simple, I want to discard it even if it's in the middle")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀕🀘🀘🀘🀜🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.should.equal(h.tiles[6]);
}

@("If I have a set with a double end, they are actually unconnected, so I want to discard the double")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀖🀗🀘🀘🀜🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.shouldBeEither(h.tiles[8], h.tiles[9]);
}

@("If I have a set with a double in the middle, I want to discard the double")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀖🀗🀗🀘🀜🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.shouldBeEither(h.tiles[7], h.tiles[8]);
}

@("If I have a set with a double at the start, I want to discard the double")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀖🀖🀗🀘🀜🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.shouldBeEither(h.tiles[6], h.tiles[7]);
}

@("If I have a set of 4, they are actually unconnected, so I want to discard either end")
unittest
{
    auto h = hand("🀀🀀🀀🀒🀒🀒🀕🀖🀗🀘🀜🀜🀠🀠"d);
    auto result = discardUnrelatedTile(h, player);
    result.selectedTile.shouldBeEither(h.tiles[6], h.tiles[9]);
}


private const(Tile) selectOnlyTileOfType(const Hand hand) pure @nogc nothrow
{
    foreach(set; hand.tilesByType)
    {
        auto first = set.front;
        set.popFront;
        if(set.empty)
        {
            return first;
        }
    }
    return null;
}

private const(Tile) selectLonelyHonour(const Hand hand) pure @nogc nothrow
{
    foreach(set; hand.honoursByValue)
    {
        auto first = set.front;
        set.popFront;
        if(set.empty)
        {
            return first;
        }
    }
    return null;
}

private const(Tile) selectUnconnectedTerminal(const Hand hand) pure @nogc nothrow
{
    foreach(set; hand.nonHonoursByType)
    {
        Rebindable!(const Tile) first;
        Rebindable!(const Tile) second = set.front;
        set.popFront;
        foreach(s; set)
        {
            first = second;
            if(first.isTerminal)
            {
                if(!first.areConnected(s)) return first;
            }
            second = s;
        }
        if(second && second.isTerminal)
        {
            if(!first.areConnected(second)) return second;
        }
    }
    return null;
}

private const(Tile) selectUnconnectedTile(const Hand hand) pure @nogc nothrow
{
    foreach(set; hand.nonHonoursByType)
    {
        Rebindable!(const Tile) first;
        Rebindable!(const Tile) second = set.front;
        set.popFront;
        if(set.empty)
        {
            return second;
        }
        Rebindable!(const Tile) third = set.front;
        if(!second.areConnected(third))
        {
            return second;
        }
        set.popFront;
        bool iterated = false;
        foreach(tile; set)
        {
            iterated = true;
            first = second;
            second = third;
            third = tile;
            if(!first.areConnected(second)
                && !second.areConnected(third))
            {
                return second;
            }
            
        }
        if(iterated &&!second.areConnected(third))
        {
            return third;
        }
    }
    return null;
}

private const(Tile) selectTileNotConnectedFromSet(const Hand hand) pure @nogc nothrow
{
    alias Tiles = NoGcArray!(14, const Tile);
    bool stripSet(ref Tiles tiles)
    {
        static foreach(seperate; AliasSeq!(seperatePon, seperateChi))
        {{
            auto set = seperate(tiles);
            if(set.isSeperated)
            {
                tiles = set.unwrap.hand;
                return true;
            }
        }}
        return false;
    }

    foreach(set; hand.nonHonoursByType)
    {
        auto tiles = set.array!14;
        while(stripSet(tiles)) {}
        if(tiles.length == 1) return tiles[0];
    }
    return null;
}

private TurnDecision discard(const Tile tile, const Player player) pure @nogc nothrow
{
    return TurnDecision(player, TurnDecision.Action.discard, tile);
}

version(mahjong_test)
{
    void shouldBeEither(T, U...)(T actual, U expected, 
        string file = __FILE__, size_t line = __LINE__)
    {
        import std.algorithm;
        import std.conv;
        import fluent.asserts;
        if(![expected].any!(exp => exp is actual))
        {
            IResult message = new MessageResult("Expected the value to be either of the supplied values.");
            IResult source = new SourceResult(file, line);
            IResult result = new ExpectedActualResult([expected].to!string, actual.to!string);
            throw new TestException([result, source], file, line);
        }
    }
}