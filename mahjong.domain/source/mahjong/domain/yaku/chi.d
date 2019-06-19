﻿module mahjong.domain.yaku.chi;

import mahjong.domain.enums;
import mahjong.domain.result;
import mahjong.domain.tile;
import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;
import mahjong.util.collections;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.ingame;
    import mahjong.domain.mahjong;
}

private alias Yakus = NoGcArray!(4, Yaku);

package Yakus determineChiBasedYaku(ref const MahjongResult result, bool isClosedHand)
  pure @nogc nothrow
{
    Yakus yakus;
    if(result.isStraightFlush)
    {
        yakus ~= Yaku.itsu;
    }
    if(isClosedHand && result.hasJustTwoEqualChis)
    {
        yakus ~= Yaku.iipeikou;
    }
    if(isClosedHand && result.hasTwoTimesTwoEqualChis)
    {
        yakus ~= Yaku.ryanPeikou;
    }
    if(result.hasTripletChis)
    {
        yakus ~= Yaku.sanShoukuDoujun;
    }
    return yakus;
}

@("A straight flush is an itsu")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀇🀇🀔🀔🀔🀙🀚🀛🀜🀝🀞🀟🀠🀡"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.itsu]);
}

@("Two equal chis in a closed hand is an iipeikou")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀇🀇🀈🀈🀉🀉🀛🀛🀛🀓🀔🀕"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.iipeikou]);
}

@("Two equal chis in an open hand is nothing")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀇🀇🀈🀈🀉🀉🀛🀛🀛🀓🀔🀕"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.not.contain([Yaku.iipeikou]);
}

@("A triplet chi is an san shoku doujun")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀇🀈🀉🀊🀊🀐🀑🀒🀙🀚🀛🀠🀠🀠"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.sanShoukuDoujun]);
}

@("Two times two identical chis in a closed hand are ryan peikou")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀇🀇🀈🀈🀉🀉🀓🀓🀔🀔🀕🀕"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.ryanPeikou]);
}

@("Two times two identical chis in an open hand are tough luck")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀇🀇🀈🀈🀉🀉🀓🀓🀔🀔🀕🀕"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.length.should.equal(0);
}

private bool isStraightFlush(const MahjongResult result) pure @nogc nothrow
{
    import std.algorithm : filter;
    import mahjong.domain.set : isChi;
    struct Straight
    {
        this(Types type) pure @nogc nothrow
        {
            this.type = type;
        }

        Types type;
        bool first;
        bool second;
    }
    Straight straight;
    foreach(set; result.sets.filter!(s => s.isChi))
    {
        auto tile = set.tiles[0];
        if(straight.type != tile.type) straight = Straight(tile.type);
        if(tile.value == Numbers.one)
        {
            straight.first = true;
        }
        if(tile.value == Numbers.four)
        {
            straight.second = true;
        }
        if(tile.value == Numbers.seven)
        {
            if(straight.first && straight.second) return true;
        }
    }
    return false;
}

@("One to nine in the same suit is a straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀊🀋🀌"d.convertToTiles);
    auto third = chi("🀍🀎🀏"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(true);
}

@("Having pons doesn't count towards a straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = pon("🀇🀇🀇"d.convertToTiles);
    auto second = pon("🀊🀊🀊"d.convertToTiles);
    auto third = pon("🀍🀍🀍"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(false);
}

@("Having three non-constructive chis in the same suit is no straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀈🀉🀊"d.convertToTiles);
    auto second = chi("🀊🀋🀌"d.convertToTiles);
    auto third = chi("🀍🀎🀏"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(false);
}

@("One to nine in the same suit is a straight flush even with a fourth chi")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀊🀋🀌"d.convertToTiles);
    auto third = chi("🀍🀎🀏"d.convertToTiles);
    auto other = chi("🀈🀉🀊"d.convertToTiles);
    auto result = MahjongResult(true, [first, other, second, third]);
    result.isStraightFlush.should.equal(true);
}

@("All constructive chis should be in the same suit for a straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀜🀝🀞"d.convertToTiles);
    auto third = chi("🀍🀎🀏"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(false);
}

private size_t countChiPairs(ref const MahjongResult mahjongResult) pure @nogc nothrow
{
    import mahjong.domain.set;
    // Until otherwise proven, assume that the result is reasonably sorted.
    size_t amountOfPairs;
    for(size_t i = 0; i < mahjongResult.sets.length - 1; ++i)
    {
        auto set = mahjongResult.sets[i];
        auto secondSet = mahjongResult.sets[i+1];
        if(set.isChi && set.isSameAs(secondSet))
        {
            ++amountOfPairs;
            ++i; //
        }
    }
    return amountOfPairs;
}

private bool hasJustTwoEqualChis(ref const MahjongResult mahjongResult) pure @nogc nothrow
{
    return mahjongResult.countChiPairs == 1;
}

@("If a hand contains two equal chis, it is recognised as such")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀇🀈🀉"d.convertToTiles);
    auto result = MahjongResult(true, [first, second]);
    result.hasJustTwoEqualChis.should.equal(true);
}

@("If a hand does not contain two equal chis, it is not a false positive")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀔🀕🀖"d.convertToTiles);
    auto result = MahjongResult(true, [first, second]);
    result.hasJustTwoEqualChis.should.equal(false);
}

@("If a hand contains two equal pons, that is still no two equal chis")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = pon("🀙🀙🀙"d.convertToTiles);
    auto second = pon("🀙🀙🀙"d.convertToTiles);
    auto result = MahjongResult(true, [first, second]);
    result.hasJustTwoEqualChis.should.equal(false);
}

@("If a hand contains two times two equal chis, that does not mean just two equal chis")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀇🀈🀉"d.convertToTiles);
    auto third = chi("🀔🀕🀖"d.convertToTiles);
    auto fourth = chi("🀔🀕🀖"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third, fourth]);
    result.hasJustTwoEqualChis.should.equal(false);
}

@("Three equal chis are rounded down to two.")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀇🀈🀉"d.convertToTiles);
    auto third = chi("🀇🀈🀉"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.hasJustTwoEqualChis.should.equal(true);
}

private bool hasTwoTimesTwoEqualChis(ref const MahjongResult mahjongResult) pure @nogc nothrow
{
    return mahjongResult.countChiPairs == 2;
}

@("If a hand contains two times two equal chis, it is two chi pairs")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀇🀈🀉"d.convertToTiles);
    auto second = chi("🀇🀈🀉"d.convertToTiles);
    auto third = chi("🀔🀕🀖"d.convertToTiles);
    auto fourth = chi("🀔🀕🀖"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third, fourth]);
    result.hasTwoTimesTwoEqualChis.should.equal(true);
}

private bool hasTripletChis(ref const MahjongResult mahjongResult) pure @nogc nothrow
{
    import mahjong.domain.set : isSameChiInDifferentType;
    if(mahjongResult.sets.length < 3) return false;
    foreach(first; mahjongResult.sets[0 .. $ - 2])
        foreach(second; mahjongResult.sets[1 .. $ - 1])
            foreach(third; mahjongResult.sets[2 .. $])
        {
            if(isSameChiInDifferentType(first, second, third)) return true;
        }
    return false;
}

@("A mahjong with three different but equally high chis has a triplet")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = chi("🀊🀋🀌"d.convertToTiles);
    auto second = chi("🀓🀔🀕"d.convertToTiles);
    auto third = chi("🀜🀝🀞"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.hasTripletChis.should.equal(true);
}

@("When attempting to check the triplets with seven pairs we should not go out of range")
unittest
{
    import mahjong.domain.set; 
    import mahjong.domain.creation;
    auto first = sevenPairs("🀑🀑🀕🀕🀒🀒🀠🀠🀀🀀🀐🀐🀅🀅"d.convertToTiles);
    auto result = MahjongResult(true, [first]);
    result.hasTripletChis.should.equal(false);
}