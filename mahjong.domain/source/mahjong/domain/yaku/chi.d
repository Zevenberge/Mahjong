module mahjong.domain.yaku.chi;

import mahjong.domain.enums;
import mahjong.domain.result;
import mahjong.domain.tile;
import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.ingame;
    import mahjong.domain.mahjong;
}

package Yaku[] determineChiBasedYaku(const MahjongResult result, bool isClosedHand)
{
    Yaku[] yakus;
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

private bool isStraightFlush(const MahjongResult result) pure
{
    import std.algorithm : any, filter;
    import std.typecons : Tuple;
    import mahjong.domain.set;
    alias Straight = Tuple!(bool, "first", bool, "second", bool, "third");
    Straight[Types] straights;
    foreach(set; result.sets.filter!(s => s.isChi))
    {
        auto tile = set.tiles[0];
        auto straight = tile.type in straights ? straights[tile.type] : Straight();
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
            straight.third = true;
        }
        straights[tile.type] = straight;
    }
    return straights.values.any!(s => s.first && s.second && s.third);
}

@("One to nine in the same suit is a straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto third = new ChiSet("🀍🀎🀏"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(true);
}

@("Having pons doesn't count towards a straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto second = new PonSet("🀊🀊🀊"d.convertToTiles);
    auto third = new PonSet("🀍🀍🀍"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(false);
}

@("Having three non-constructive chis in the same suit is no straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀈🀉🀊"d.convertToTiles);
    auto second = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto third = new ChiSet("🀍🀎🀏"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(false);
}

@("One to nine in the same suit is a straight flush even with a fourth chi")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto third = new ChiSet("🀍🀎🀏"d.convertToTiles);
    auto other = new ChiSet("🀈🀉🀊"d.convertToTiles);
    auto result = MahjongResult(true, [first, other, second, third]);
    result.isStraightFlush.should.equal(true);
}

@("All constructive chis should be in the same suit for a straight flush")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀜🀝🀞"d.convertToTiles);
    auto third = new ChiSet("🀍🀎🀏"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.isStraightFlush.should.equal(false);
}

private size_t countChiPairs(const MahjongResult mahjongResult)
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

private bool hasJustTwoEqualChis(const MahjongResult mahjongResult)
{
    return mahjongResult.countChiPairs == 1;
}

@("If a hand contains two equal chis, it is recognised as such")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto result = MahjongResult(true, [first, second]);
    result.hasJustTwoEqualChis.should.equal(true);
}

@("If a hand does not contain two equal chis, it is not a false positive")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀔🀕🀖"d.convertToTiles);
    auto result = MahjongResult(true, [first, second]);
    result.hasJustTwoEqualChis.should.equal(false);
}

@("If a hand contains two equal pons, that is still no two equal chis")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto second = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto result = MahjongResult(true, [first, second]);
    result.hasJustTwoEqualChis.should.equal(false);
}

@("If a hand contains two times two equal chis, that does not mean just two equal chis")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto third = new ChiSet("🀔🀕🀖"d.convertToTiles);
    auto fourth = new ChiSet("🀔🀕🀖"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third, fourth]);
    result.hasJustTwoEqualChis.should.equal(false);
}

@("Three equal chis are rounded down to two.")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto third = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.hasJustTwoEqualChis.should.equal(true);
}

private bool hasTwoTimesTwoEqualChis(const MahjongResult mahjongResult)
{
    return mahjongResult.countChiPairs == 2;
}

@("If a hand contains two times two equal chis, it is two chi pairs")
unittest
{
    import mahjong.domain.set;
    import mahjong.domain.creation;
    auto first = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto second = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto third = new ChiSet("🀔🀕🀖"d.convertToTiles);
    auto fourth = new ChiSet("🀔🀕🀖"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third, fourth]);
    result.hasTwoTimesTwoEqualChis.should.equal(true);
}

private bool hasTripletChis(const MahjongResult mahjongResult)
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
    auto first = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto second = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto third = new ChiSet("🀜🀝🀞"d.convertToTiles);
    auto result = MahjongResult(true, [first, second, third]);
    result.hasTripletChis.should.equal(true);
}

@("When attempting to check the triplets with seven pairs we should not go out of range")
unittest
{
    import mahjong.domain.set; 
    import mahjong.domain.creation;
    auto first = new SevenPairsSet("🀑🀑🀕🀕🀒🀒🀠🀠🀀🀀🀐🀐🀅🀅"d.convertToTiles);
    auto result = MahjongResult(true, [first]);
    result.hasTripletChis.should.equal(false);
}