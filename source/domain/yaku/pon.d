module mahjong.domain.yaku.pon;

import mahjong.domain.enums;
import mahjong.domain.result;
import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.ingame;
    import mahjong.engine.mahjong;
}

package Yaku[] determinePonBasedYaku(const MahjongResult result, Environment environment)
{
    Yaku[] yakus;
    auto amountOfFanpai = result.countFanpai(environment.leadingWind, environment.ownWind);
    for(int i = 0; i < amountOfFanpai; ++i) 
    {
        yakus ~= Yaku.fanpai;
    }
    if(result.hasOnlyPons) 
    {
        yakus ~= Yaku.toiToiHou;
    }
    if(result.amountOfConsealedPons == 3)
    {
        yakus ~= Yaku.sanAnkou;
    }
    if(result.amountOfKans == 3)
    {
        yakus ~= Yaku.sanKanTsu;
    }
    if(result.isThreeLittleDragons)
    {
        yakus ~= Yaku.shouSangen;
    }
    if(result.hasPonInAllThreeSuits)
    {
        yakus ~= Yaku.sanShokuDokou;
    }
    return yakus;
}

@("The amount of fanpai gets added to the yaku count")
unittest
{
    import fluent.asserts;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀀🀄🀄🀄🀒🀒🀖🀗🀘🀜🀝🀞"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.east,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.fanpai, Yaku.fanpai, Yaku.fanpai]);
}

@("Only pons is toi toi hou")
unittest
{
    import fluent.asserts;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀀🀒🀒🀒🀙🀙🀙🀠🀠🀡🀡🀡"d);
    game.closedHand.tiles[0].isNotOwn;
    game.closedHand.tiles[4].isNotOwn;
    game.closedHand.tiles[7].isNotOwn;
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.toiToiHou]);
}

@("Three consealed pons is san ankou")
unittest
{
    import fluent.asserts;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀀🀒🀒🀒🀖🀗🀘🀙🀙🀙🀠🀠"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.sanAnkou]);
}

@("Three kans is san kan tsu")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.east, "🀖🀗🀘🀙🀙"d);
    game.openHand.addKan("🀄🀄🀄🀄"d.convertToTiles);
    game.openHand.addKan("🀡🀡🀡🀡"d.convertToTiles);
    game.openHand.addKan("🀌🀌🀌🀌"d.convertToTiles);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.sanKanTsu, Yaku.sanAnkou, Yaku.fanpai]);
}

@("Two kans is no san kan tsu")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.east, "🀖🀗🀘🀙🀙🀚🀚🀚"d);
    game.openHand.addKan("🀡🀡🀡🀡"d.convertToTiles);
    game.openHand.addKan("🀌🀌🀌🀌"d.convertToTiles);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.sanAnkou]);
}

@("Three little dragons is shou sangen")
unittest
{
    import fluent.asserts;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.east, "🀅🀅🀅🀄🀄🀄🀆🀆🀖🀗🀘🀜🀝🀞"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.fanpai, Yaku.fanpai, Yaku.shouSangen]);
}

@("Three times the same pon is san shoku dokou")
unittest
{
    import fluent.asserts;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.east, "🀇🀇🀇🀉🀊🀋🀐🀐🀐🀒🀒🀙🀙🀙"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.sanShokuDokou, Yaku.sanAnkou]);
}

private size_t countFanpai(const MahjongResult result, PlayerWinds leadingWind, PlayerWinds ownWind)
{
    import mahjong.domain.set;
    size_t fanpai = 0;
    foreach(set; result.sets)
    {
        if(!set.isPon) continue;
        if(set.isSetOf(Types.dragon)) ++fanpai;
        if(set.isSetOf(Types.wind))
        {
            auto tile = set.tiles[0];
            if(tile.value == leadingWind) ++fanpai;
            if(tile.value == ownWind) ++fanpai;
        }
    }
    return fanpai;
}

@("Having a pon of dragons counts as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀄🀄🀄"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(1);
}

@("Having a pair of dragons does not count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PairSet("🀄🀄"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(0);
}

@("Having a pon of simples does not count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀐🀐🀐"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(0);
}

@("Having a pon of own winds count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀂🀂🀂"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(1);
}

@("Having a pon of leading winds count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀀🀀🀀"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(1);
}

@("Having a pon of winds which is not leading nor own is no fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀁🀁🀁"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(0);
}

@("Having a pon of winds which is both leading and own count as two fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀀🀀🀀"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.east).should.equal(2);
}

private size_t amountOfConsealedPons(const MahjongResult result)
{
    import std.algorithm : count;
    import mahjong.domain.set;
    return result.sets.count!(s => s.isPon && !s.isOpen);
}

@("A consealed pon is counted as one")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pon = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [pon]);
    result.amountOfConsealedPons.should.equal(1);
}

@("Multiple consealed pons are all counted")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pon = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [pon, pon, pon]);
    result.amountOfConsealedPons.should.equal(3);
}

@("An open pon is not counted as a consealed pon")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto tiles = "🀀🀀🀀"d.convertToTiles;
    tiles[0].isNotOwn;
    auto result = MahjongResult(true, [new PonSet(tiles)]);
    result.amountOfConsealedPons.should.equal(0);
}

@("A pair or a chi are not counted as consealed pons")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pair = new PairSet("🀀🀀"d.convertToTiles);
    auto chi = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi]);
    result.amountOfConsealedPons.should.equal(0);
}

private size_t amountOfKans(const MahjongResult result)
{
    import std.algorithm : count;
    import mahjong.domain.set;
    return result.sets.count!(s => s.isKan);
}

@("A kan is counted as one")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto kan = new PonSet("🀡🀡🀡🀡"d.convertToTiles);
    auto result = MahjongResult(true, [kan]);
    result.amountOfKans.should.equal(1);
}

@("Multiple kans are all counted")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto kan = new PonSet("🀡🀡🀡🀡"d.convertToTiles);
    auto result = MahjongResult(true, [kan, kan, kan]);
    result.amountOfKans.should.equal(3);
}

@("A simple pon is not counted as a kan")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pon = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [pon]);
    result.amountOfKans.should.equal(0);
}

@("A pair or a chi is not counted as a kan")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pair = new PairSet("🀀🀀"d.convertToTiles);
    auto chi = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi]);
    result.amountOfKans.should.equal(0);
}

private bool isThreeLittleDragons(const MahjongResult result)
{
    import mahjong.domain.set;
    bool pair;
    size_t pons;
    foreach(set; result.sets)
    {
        if(!set.isSetOf(Types.dragon)) continue;
        if(set.isPair) pair = true;
        else ++pons;
    }
    return pair && pons == 2;
}

@("A pair and two pons of dragons is three little dragons")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pair = new PairSet("🀄🀄"d.convertToTiles);
    auto pon1 = new PonSet("🀅🀅🀅"d.convertToTiles);
    auto pon2 = new PonSet("🀆🀆🀆"d.convertToTiles);
    auto result = MahjongResult(true, [pair, pon1, pon2]);
    result.isThreeLittleDragons.should.equal(true);
}

@("Three pons of dragons is not three little dragons")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pon = new PonSet("🀄🀄🀄"d.convertToTiles);
    auto pon1 = new PonSet("🀅🀅🀅"d.convertToTiles);
    auto pon2 = new PonSet("🀆🀆🀆"d.convertToTiles);
    auto result = MahjongResult(true, [pon, pon1, pon2]);
    result.isThreeLittleDragons.should.equal(false);
}

@("One pon of dragons and a pair is not enough for three little dragons")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pair = new PairSet("🀄🀄"d.convertToTiles);
    auto pon1 = new PonSet("🀅🀅🀅"d.convertToTiles);
    auto result = MahjongResult(true, [pair, pon1]);
    result.isThreeLittleDragons.should.equal(false);
}

@("Tiles other than dragons don't count for the three little dragons")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto pair = new PairSet("🀇🀇"d.convertToTiles);
    auto pon1 = new PonSet("🀌🀌🀌"d.convertToTiles);
    auto pon2 = new PonSet("🀗🀗🀗"d.convertToTiles);
    auto result = MahjongResult(true, [pair, pon1, pon2]);
    result.isThreeLittleDragons.should.equal(false);
}

private bool hasPonInAllThreeSuits(const MahjongResult result)
{
    import std.algorithm : any;
    import std.conv : to;
    import mahjong.domain.set;
    import mahjong.share.collections : Set;
    Set!Types[Numbers] stats;
    foreach(set; result.sets)
    {
        if(!set.isPon) continue;
        if(set.isSetOf(Types.dragon)) continue;
        if(set.isSetOf(Types.wind)) continue;
        auto number = set.tiles[0].value.to!Numbers;
        if(number !in stats)
        {
            stats[number] = Set!Types.init;
        }
        stats[number] ~= set.tiles[0].type;
    }
    return stats.byValue.any!(s => s.length == 3);
}

@("If I have the same pon in three suits, it should be recognized as such")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto chars = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto bamboo = new PonSet("🀐🀐🀐"d.convertToTiles);
    auto balls = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto result = MahjongResult(true, [chars, bamboo, balls]);
    result.hasPonInAllThreeSuits.should.equal(true);
}

@("If I have a double, it still doesn't matter")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto chars = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto bamboo = new PonSet("🀐🀐🀐"d.convertToTiles);
    auto balls = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto result = MahjongResult(true, [chars, bamboo, balls, chars]);
    result.hasPonInAllThreeSuits.should.equal(true);
}

@("Pons with different values don't count")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto chars = new PonSet("🀈🀈🀈"d.convertToTiles);
    auto bamboo = new PonSet("🀐🀐🀐"d.convertToTiles);
    auto balls = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto result = MahjongResult(true, [chars, bamboo, balls]);
    result.hasPonInAllThreeSuits.should.equal(false);
}

@("Chis don't count towards the different pons")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto chars = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto bamboo = new PonSet("🀐🀐🀐"d.convertToTiles);
    auto balls = new ChiSet("🀙🀚🀛"d.convertToTiles);
    auto result = MahjongResult(true, [chars, bamboo, balls]);
    result.hasPonInAllThreeSuits.should.equal(false);
}

@("Dragons and winds don't count towards the different types")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    import mahjong.engine.creation;
    auto chars = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto dragons = new PonSet("🀅🀅🀅"d.convertToTiles);
    auto winds = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [chars, dragons, winds]);
    result.hasPonInAllThreeSuits.should.equal(false);
}