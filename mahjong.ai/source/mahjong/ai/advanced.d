module mahjong.ai.advanced;

import std.algorithm;
import std.array;
import std.meta;
import std.typecons;
import mahjong.ai;
import mahjong.ai.data;
import mahjong.ai.decision;
import mahjong.domain.player;
import mahjong.domain.tile;

version(mahjong_test)
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
        selectLonelyHonour
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

private TurnDecision discard(const Tile tile, const Player player) pure @nogc nothrow
{
    return TurnDecision(player, TurnDecision.Action.discard, tile);
}