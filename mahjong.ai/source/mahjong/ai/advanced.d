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
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine.flow;
import mahjong.util.collections;
import mahjong.util.optional;

alias Hand = mahjong.ai.data.Hand;

version(mahjong_ai_test)
{
    import fluent.asserts;
    import mahjong.ai.testing;
}

class AdvancedAI : AI
{
    const(TurnDecision) decide(const TurnEvent event)
    {
        auto redraw = declareRedrawIfPossible(event.player, event.metagame);
        if(redraw != none) return redraw.get;
        auto tsumo = claimTsumoIfPossible(event.player, event.metagame);
        if(tsumo != none) return tsumo.get;
        auto riichi = declareRiichiIfPossible(event.player, event.metagame);
        if(riichi != none) return riichi.get;
        auto hand = Hand(event.player.closedHand.tiles);
        auto discard = discardUnrelatedTile(hand, event.player);
        auto kan = tryToFitInAKan(discard, event.player);
        if(kan != none) return kan.get;
        return discard;
    }

    @("The AI should tsumo if they can.")
    unittest
    {
        import mahjong.domain.enums;
        import mahjong.domain.opts;
        import mahjong.domain.wall;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        metagame.wall = new Wall(new DefaultGameOpts);
        metagame.wall.setUp;
        auto player = new Player("🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d, PlayerWinds.east);
        player.hasDrawnTheirLastTile;
        auto ai = new AdvancedAI();
        auto result = ai.decide(new TurnEvent(metagame, player, player.lastTile));
        result.action.should.equal(TurnDecision.Action.claimTsumo);
        result.player.should.equal(player);
    }

    @("If the AI cannot tsumo, they should discard a tile")
    unittest
    {
        import mahjong.domain.enums;
        import mahjong.domain.opts;
        import mahjong.domain.wall;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        metagame.wall = new Wall(new DefaultGameOpts);
        metagame.wall.setUp;
        auto player = new Player("🀁🀁🀆🀆🀆🀑🀑🀓🀕🀇🀙🀜🀝🀡"d, PlayerWinds.east);
        player.hasDrawnTheirLastTile;
        auto ai = new AdvancedAI();
        auto result = ai.decide(new TurnEvent(metagame, player, player.lastTile));
        result.action.should.equal(TurnDecision.Action.discard);
        result.player.should.equal(player);
        result.selectedTile.should.equal(player.closedHand.tiles[9]);
    }

    @("If the AI can declare riichi, they should")
    unittest
    {
        import mahjong.domain.enums;
        import mahjong.domain.opts;
        import mahjong.domain.wall;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        metagame.wall = new Wall(new DefaultGameOpts);
        metagame.wall.setUp;
        auto player = new Player("🀀🀀🀇🀇🀈🀈🀉🀉🀓🀓🀔🀔🀕🀡"d, PlayerWinds.east);
        player.hasDrawnTheirLastTile;
        auto ai = new AdvancedAI();
        auto result = ai.decide(new TurnEvent(metagame, player, player.lastTile));
        result.action.should.equal(TurnDecision.Action.declareRiichi);
        result.player.should.equal(player);
        result.selectedTile.shouldBeEither(player.closedHand.tiles[12],
            player.closedHand.tiles[13]);
    }

    @("If a fourth tile is relevant, discard another")
    unittest
    {
        import mahjong.domain.enums;
        import mahjong.domain.opts;
        import mahjong.domain.wall;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        metagame.wall = new Wall(new DefaultGameOpts);
        metagame.wall.setUp;
        auto player = new Player("🀀🀀🀀🀒🀒🀒🀖🀗🀗🀗🀘🀜🀡"d, PlayerWinds.east);
        auto tile = new Tile(Types.bamboo, Numbers.eight);
        tile.isNotOwn;
        player.pon(tile);
        auto ai = new AdvancedAI();
        auto result = ai.decide(new TurnEvent(metagame, player, player.lastTile));
        result.action.should.equal(TurnDecision.Action.discard);
        result.selectedTile.shouldBeEither(player.closedHand.tiles[9], player.closedHand.tiles[10]);
    }

    @("If the fourth tile is irrelevant, just promote it to kan")
    unittest
    {
        import mahjong.domain.enums;
        import mahjong.domain.opts;
        import mahjong.domain.wall;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        metagame.wall = new Wall(new DefaultGameOpts);
        metagame.wall.setUp;
        auto player = new Player("🀁🀁🀆🀆🀆🀑🀑🀓🀕🀙🀜🀝🀡"d, PlayerWinds.east);
        auto tile = new Tile(Types.dragon, Dragons.white);
        tile.isNotOwn;
        player.pon(tile);
        player.hasDrawnTheirLastTile;
        auto ai = new AdvancedAI();
        auto result = ai.decide(new TurnEvent(metagame, player, player.lastTile));
        result.action.should.equal(TurnDecision.Action.promoteToKan);
        result.player.should.equal(player);
        result.selectedTile.should.equal(player.closedHand.tiles[2]);
    }

    @("If the AI can declare a redraw, then it won't discard something")
    unittest
    {
        import mahjong.domain.enums;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        auto player = new Player("🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d, PlayerWinds.east);
        auto ai = new AdvancedAI();
        auto result = ai.decide(new TurnEvent(metagame, player, player.lastTile));
        result.player.should.equal(player);
        result.action.should.equal(TurnDecision.Action.declareRedraw);
    }

    const(ClaimDecision) decide(const ClaimEvent event)
    {
        return ClaimDecision();
    }

	const(KanStealDecision) decide(const KanStealEvent event)
    {
        return KanStealDecision();
    }
}

Optional!TurnDecision declareRedrawIfPossible(const Player player, const Metagame metagame)
    pure @nogc nothrow
{
    import mahjong.domain.ingame : isEligibleForRedraw;
    if(player.isEligibleForRedraw(metagame))
        return some(TurnDecision(player, TurnDecision.Action.declareRedraw, null));
    return no!TurnDecision;
}

@("If the AI can rage quit, it won't hesitate")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto player = new Player("🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d, PlayerWinds.east);
    auto result = declareRedrawIfPossible(player, metagame);
    result.should.not.equal(no!TurnDecision);
    result.unwrap.player.should.equal(player);
    result.unwrap.action.should.equal(TurnDecision.Action.declareRedraw);
}

@("If the AI cannot rage quit, it won't")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    auto player = new Player("🀇🀇🀔🀔🀔🀙🀚🀛🀜🀝🀞🀟🀠🀡"d, PlayerWinds.east);
    auto result = declareRedrawIfPossible(player, metagame);
    result.should.equal(no!TurnDecision);
}

Optional!TurnDecision claimTsumoIfPossible(const Player player, const Metagame metagame)
    pure
{
    if(player.canTsumo(metagame))
        return some(TurnDecision(player, TurnDecision.Action.claimTsumo, null));
    else
        return no!TurnDecision;
}

@("If they can win, the AI should claim tsumo.")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    auto player = new Player("🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d, PlayerWinds.east);
    player.hasDrawnTheirLastTile;
    auto result = claimTsumoIfPossible(player, metagame);
    result.should.not.equal(no!TurnDecision);
    result.unwrap.action.should.equal(TurnDecision.Action.claimTsumo);
    result.unwrap.player.should.equal(player);
}

@("If the player is not allowed to tsumo, the decision is not yet made")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    auto player = new Player("🀐🀐🀐🀑🀒🀓🀔🀕🀇🀇🀜🀝🀞", PlayerWinds.east);
    auto ponTile = new Tile(Types.character, Numbers.one);
    ponTile.isNotOwn;
    ponTile.isDiscarded;
    player.pon(ponTile);
    player.hasDrawnTheirLastTile;
    auto result = claimTsumoIfPossible(player, metagame);
    result.should.equal(no!TurnDecision);
}

Optional!TurnDecision declareRiichiIfPossible(const Player player, const Metagame metagame)
{
    if(!player.isClosedHand) return no!TurnDecision;
    foreach(tile; player.closedHand.tiles)
    {
        if(player.canDeclareRiichi(tile, metagame))
        {
            return some(TurnDecision(player, TurnDecision.Action.declareRiichi, tile));
        }
    }
    return no!TurnDecision;
}

@("If I can declare riichi, I will")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;
    import mahjong.domain.wall;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    metagame.wall = new Wall(new DefaultGameOpts);
    auto player = new Player("🀇🀇🀇🀉🀊🀋🀍🀐🀐🀒🀒🀙🀙🀙", PlayerWinds.east);
    player.hasDrawnTheirLastTile;
    auto result = declareRiichiIfPossible(player, metagame);
    result.should.not.equal(no!TurnDecision);
    result.unwrap.action.should.equal(TurnDecision.Action.declareRiichi);
    result.unwrap.player.should.equal(player);
    result.unwrap.selectedTile.should.equal(player.closedHand.tiles[6]);
}

@("If I can't declare riichi, I won't")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;
    import mahjong.domain.wall;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    metagame.wall = new Wall(new DefaultGameOpts);
    auto player = new Player("🀅🀄🀆🀇🀈🀉🀊🀋🀌🀍🀎🀏🀐🀑", PlayerWinds.east);
    player.hasDrawnTheirLastTile;
    auto result = declareRiichiIfPossible(player, metagame);
    result.should.equal(no!TurnDecision);
}

@("If the wall has run out, the AI can't declare riichi either")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;
    import mahjong.domain.wall;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    metagame.wall = new Wall(new DefaultGameOpts);
    metagame.wall.setUp();
    while(metagame.wall.canRiichiBeDeclared)
    {
        metagame.wall.drawTile;
    }
    auto player = new Player("🀇🀇🀇🀉🀊🀋🀍🀐🀐🀒🀒🀙🀙🀙", PlayerWinds.east);
    player.hasDrawnTheirLastTile;
    auto result = declareRiichiIfPossible(player, metagame);
    result.should.equal(no!TurnDecision);
}

@("If I can declare riichi on a not so obvious tile, I still will")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;
    import mahjong.domain.wall;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    metagame.wall = new Wall(new DefaultGameOpts);
    auto player = new Player("🀀🀀🀀🀆🀈🀈🀍🀍🀑🀑🀖🀖🀙🀙", PlayerWinds.east);
    player.hasDrawnTheirLastTile;
    auto result = declareRiichiIfPossible(player, metagame);
    result.should.not.equal(no!TurnDecision);
    result.unwrap.action.should.equal(TurnDecision.Action.declareRiichi);
    result.unwrap.player.should.equal(player);
    result.unwrap.selectedTile.should.equal(player.closedHand.tiles[0]);
}

TurnDecision discardUnrelatedTile(ref const Hand hand, const Player player) pure @nogc nothrow
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
    auto h = hand("🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d);
    auto result = discardUnrelatedTile(h, player);
    result.action.should.equal(TurnDecision.Action.discard);
}

@("The decision should include the player it was made for")
unittest
{
    auto p = player;
    auto h = hand("🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d);
    auto result = discardUnrelatedTile(h, p);
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
    auto h = hand("🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀🀀"d);
    auto result = discardUnrelatedTile(h, player);
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

Optional!TurnDecision tryToFitInAKan(const TurnDecision discard, 
    const Player player) pure @nogc nothrow
{
    if(player.canPromoteToKan(discard.selectedTile))
        return some(TurnDecision(player, TurnDecision.Action.promoteToKan, discard.selectedTile));
    if(player.canDeclareClosedKan(discard.selectedTile))
        return some(TurnDecision(player, TurnDecision.Action.declareClosedKan, discard.selectedTile));
    return no!TurnDecision;
}

@("If I have an open pon and want to discard the fourth tile, why not promote it")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    auto player = new Player("🀁🀁🀆🀆🀆🀑🀑🀓🀕🀙🀜🀝🀡"d, PlayerWinds.east);
    auto tile = new Tile(Types.dragon, Dragons.white);
    tile.isNotOwn;
    player.pon(tile);
    player.hasDrawnTheirLastTile;
    auto previousResult = TurnDecision(player, TurnDecision.Action.discard, player.closedHand.tiles[2]);
    auto newResult = tryToFitInAKan(previousResult, player);
    newResult.should.not.equal(no!TurnDecision);
    newResult.unwrap.action.should.equal(TurnDecision.Action.promoteToKan);
    newResult.unwrap.player.should.equal(player);
    newResult.unwrap.selectedTile.should.equal(player.closedHand.tiles[2]);
}

@("If I can't make a kan out of it, I just give up.")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    auto player = new Player("🀁🀁🀆🀆🀆🀑🀑🀓🀕🀙🀙🀜🀝🀡"d, PlayerWinds.east);
    player.hasDrawnTheirLastTile;
    auto previousResult = TurnDecision(player, TurnDecision.Action.discard, player.closedHand.tiles[2]);
    auto newResult = tryToFitInAKan(previousResult, player);
    newResult.should.equal(no!TurnDecision);
}

@("If I don't need my fourth tile and want to discard it, why not declare a closed kan")
unittest
{
    import mahjong.domain.enums;
    import mahjong.domain.opts;

    auto metagame = new Metagame([new Player], new DefaultGameOpts);
    auto player = new Player("🀁🀁🀆🀆🀆🀆🀑🀑🀓🀕🀙🀜🀝🀡"d, PlayerWinds.east);
    player.hasDrawnTheirLastTile;
    auto previousResult = TurnDecision(player, TurnDecision.Action.discard, player.closedHand.tiles[2]);
    auto newResult = tryToFitInAKan(previousResult, player);
    newResult.should.not.equal(no!TurnDecision);
    newResult.unwrap.action.should.equal(TurnDecision.Action.declareClosedKan);
    newResult.unwrap.player.should.equal(player);
    newResult.unwrap.selectedTile.should.equal(player.closedHand.tiles[2]);
}

private const(Tile) selectOnlyTileOfType(ref const Hand hand) pure @nogc nothrow
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

private const(Tile) selectLonelyHonour(ref const Hand hand) pure @nogc nothrow
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

private const(Tile) selectUnconnectedTerminal(ref const Hand hand) pure @nogc nothrow
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

private const(Tile) selectUnconnectedTile(ref const Hand hand) pure @nogc nothrow
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

private const(Tile) selectTileNotConnectedFromSet(ref const Hand hand) pure @nogc nothrow
{
    alias Tiles = NoGcArray!(14, const Tile);
    bool stripSet(ref Tiles tiles)
    {
        static foreach(seperate; AliasSeq!(seperatePon, seperateChi))
        {{
            auto set = seperate(tiles);
            if(set.isSeperated)
            {
                return true;
            }
        }}
        return false;
    }

    foreach(suit; hand.nonHonoursByType)
    {
        auto tiles = suit.array!14;
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