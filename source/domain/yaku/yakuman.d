module mahjong.domain.yaku.yakuman;

import mahjong.domain.enums;
import mahjong.domain.result;
import mahjong.domain.set;
import mahjong.domain.tile;
import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;
import mahjong.domain.yaku.pon;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.ingame;
    import mahjong.engine.mahjong;
}

package Yaku[] determineYakuman(const MahjongResult mahjongResult, const Environment environment)
{
    Yaku[] yakus;
    if(mahjongResult.isThirteenOrphans)
    {
        yakus ~= Yaku.kokushiMusou;
    }
    if(environment.isClosedHand && mahjongResult.isNineGates)
    {
        yakus ~= Yaku.chuurenPooto;
    }
    if(environment.isFirstRound)
    {
        yakus ~= environment.firstRoundYaku;
    }
    if(mahjongResult.amountOfConsealedPons == 4)
    {
        yakus ~= Yaku.suuAnkou;
    }
    if(mahjongResult.amountOfKans == 4)
    {
        yakus ~= Yaku.suuKanTsu;
    }
    return yakus;
}

@("Thirteen orphans is koku shimusou")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀀🀁🀂🀃🀄🀄🀅🀆🀇🀏🀐🀘🀙🀡"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isSelfDraw: false,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.kokushiMusou]);
}

@("Nine gates is chuurenpooto")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀐🀐🀐🀑🀒🀓🀔🀕🀕🀖🀗🀘🀘🀘"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand:true 
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.chuurenPooto]);
}

@("Nine gates should be closed")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀐🀐🀐🀑🀒🀓🀔🀕🀕🀖🀗🀘🀘🀘"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand:false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.not.contain([Yaku.chuurenPooto]);
}

@("An east mahjong in the first round on a self-draw is tenho")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.east,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isFirstRound: true,
            isSelfDraw: true,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.tenho]);
}

@("A non-east mahjong in the first round on a self-draw is chiho")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.south,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isFirstRound: true,
            isSelfDraw: true,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.chiho]);
}

@("A mahjong in the first round on a discard is renho")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.south,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isFirstRound: true,
            isSelfDraw: false,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.renho]);
}

@("Four consealed pons is suu ankou")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀀🀒🀒🀒🀔🀔🀔🀙🀙🀙🀠🀠"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isSelfDraw: true,
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.suuAnkou]);
}

@("Four kans is suu kan tsu")
unittest
{
    import mahjong.engine.creation;
    auto game = new Ingame(PlayerWinds.east, "🀠🀠"d);
    auto claimedTile = new Tile(Types.dragon, Dragons.red);
    claimedTile.origin = new Ingame(PlayerWinds.west, ""d);
    game.openHand.addKan("🀄🀄🀄"d.convertToTiles ~ claimedTile);
    game.openHand.addKan("🀙🀙🀙🀙"d.convertToTiles);
    game.openHand.addKan("🀡🀡🀡🀡"d.convertToTiles);
    game.openHand.addKan("🀌🀌🀌🀌"d.convertToTiles);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isSelfDraw: true,
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.suuKanTsu]);
}

private Yaku firstRoundYaku(const Environment environment)
{
    if(environment.isSelfDraw)
    {
        if(environment.ownWind == PlayerWinds.east)
        {
            return Yaku.tenho;
        }
        else
        {
            return Yaku.chiho;
        }
    }
    else
    {
        return Yaku.renho;
    }
}

private bool isNineGates(const MahjongResult result)
{
    import std.algorithm : any, count;
    import std.array : array;
    if(result.sets.length != 5 
        || result.sets.any!(s => s.isKan)
        || !result.tiles.isAllOfSameSuit)
    {
        return false;
    }
    auto tiles = result.tiles.array;
    foreach(number; [Numbers.one, Numbers.nine])
    {
        if(tiles.count!(t => t.value == number) < 3) return false;
    }
    foreach(number; Numbers.two .. Numbers.eight)
    {
        if(!tiles.any!(t => t.value == number)) return false;
    }
    return true;
}

@("Seven pairs is not nine gates")
unittest
{
    auto result = MahjongResult(true, [new SevenPairsSet(null)]);
    result.isNineGates.should.equal(false);
}

@("1-1-1-2-3-4-5-6-7-8-9-9-9 with a double 5 is nine gates")
unittest
{
    import mahjong.engine.creation : convertToTiles;
    auto ones = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto twoThreeFour = new ChiSet("🀈🀉🀊"d.convertToTiles);
    auto fives = new PairSet("🀋🀋"d.convertToTiles);
    auto sixSevenEight = new ChiSet("🀌🀍🀎"d.convertToTiles);
    auto nines = new PonSet("🀏🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [ones, twoThreeFour, fives, sixSevenEight, nines]);
    result.isNineGates.should.equal(true);
}

@("1-1-1-2-3-4-5-6-7-8-9-9-9 with a double 8 is nine gates")
unittest
{
    import mahjong.engine.creation : convertToTiles;
    auto ones = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto twoThreeFour = new ChiSet("🀈🀉🀊"d.convertToTiles);
    auto fiveSixSeven = new ChiSet("🀋🀌🀍"d.convertToTiles);
    auto eights = new PairSet("🀎🀎"d.convertToTiles);
    auto nines = new PonSet("🀏🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [ones, twoThreeFour, fiveSixSeven, eights, nines]);
    result.isNineGates.should.equal(true);
}

@("1-1-1-2-3-4-5-6-7-8-9-7-8-9 is not nine gates")
unittest
{
    import mahjong.engine.creation : convertToTiles;
    auto ones = new PairSet("🀇🀇"d.convertToTiles);
    auto oneTwoThree = new ChiSet("🀇🀈🀉"d.convertToTiles);
    auto fourFiveSix = new ChiSet("🀊🀋🀌"d.convertToTiles);
    auto sevenEightNine = new ChiSet("🀍🀎🀏"d.convertToTiles);
    auto result = MahjongResult(true, [ones, oneTwoThree, fourFiveSix, sevenEightNine, sevenEightNine]);
    result.isNineGates.should.equal(false);
}

@("1-1-1-3-4-5-6-7-7-8-8-9-9-9 is not nine gates")
unittest
{
    import mahjong.engine.creation : convertToTiles;
    auto ones = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto threeFourFive = new ChiSet("🀉🀊🀋"d.convertToTiles);
    auto sixSevenEight = new ChiSet("🀌🀍🀎"d.convertToTiles);
    auto sevenEightNine = new ChiSet("🀍🀎🀏"d.convertToTiles);
    auto nines = new PairSet("🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [ones, threeFourFive, sixSevenEight, sevenEightNine, nines]);
    result.isNineGates.should.equal(false);
}

@("Nine gates with a kan is not nine gates")
unittest
{
    import mahjong.engine.creation : convertToTiles;
    auto ones = new PonSet("🀇🀇🀇🀇"d.convertToTiles);
    auto twoThreeFour = new ChiSet("🀈🀉🀊"d.convertToTiles);
    auto fiveSixSeven = new ChiSet("🀋🀌🀍"d.convertToTiles);
    auto eights = new PairSet("🀎🀎"d.convertToTiles);
    auto nines = new PonSet("🀏🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [ones, twoThreeFour, fiveSixSeven, eights, nines]);
    result.isNineGates.should.equal(false);
}

@("Nine gates should be of one colour")
unittest
{
    import mahjong.engine.creation : convertToTiles;
    auto ones = new PonSet("🀙🀙🀙"d.convertToTiles);
    auto twoThreeFour = new ChiSet("🀈🀉🀊"d.convertToTiles);
    auto fives = new PairSet("🀋🀋"d.convertToTiles);
    auto sixSevenEight = new ChiSet("🀌🀍🀎"d.convertToTiles);
    auto nines = new PonSet("🀏🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [ones, twoThreeFour, fives, sixSevenEight, nines]);
    result.isNineGates.should.equal(false);
}
