module mahjong.domain.yaku.hand;

import mahjong.domain.result;
import mahjong.domain.tile;
import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.enums;
    import mahjong.domain.ingame;
    import mahjong.domain.mahjong;
}

package Yaku[] determineWholeHandYaku(const MahjongResult mahjongResult, Environment environment)
{
    Yaku[] yakus;
    if(environment.isClosedHand && mahjongResult.tiles.isAllSimples)
    {
        yakus ~= Yaku.tanyao;
    }
    if(mahjongResult.isSevenPairs)
    {
        yakus ~= Yaku.chiiToitsu;
    }
    if(mahjongResult.tiles.isAllOfSameSuit)
    {
        yakus ~= Yaku.chinitsu;
    }
    if(mahjongResult.tiles.isHalfFlush)
    {
        yakus ~= Yaku.honitsu;
    }
    if(mahjongResult.tiles.isAllHonourOrTerminal)
    {
        yakus ~= Yaku.honroutou;
    }
    if(mahjongResult.hasAtLeastOneChi)
    {
        if(mahjongResult.allSetsHaveATerminal)
        {
            yakus ~= Yaku.junchan;
        }
        else if(mahjongResult.allSetsHaveHonoursOrATerminal)
        {
            yakus ~= Yaku.chanta;
        }
    }
    if(environment.isClosedHand && mahjongResult.hasOnlyChis 
        && mahjongResult.hasValuelessPair(environment.leadingWind, environment.ownWind)
        && mahjongResult.isTwoSidedWait(environment.lastTile))
    {
        yakus ~= Yaku.pinfu;
    }
    return yakus;
}

@("If the hand is all simples and open, it does not count as a yaku")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀚🀚🀚🀜🀝🀝🀞🀞🀟🀓🀔🀕🀖🀖"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.length.should.equal(0);
}

@("If the hand is all simples and closed, it is tanyao")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀚🀚🀚🀜🀝🀝🀞🀞🀟🀓🀔🀕🀖🀖"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.tanyao]);
}

@("If the hand is seven pairs, the yaku is chiitoitsu")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.chiiToitsu]);
}

@("For a full flush, we get chinitsu")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀙🀙🀚🀚🀚🀜🀝🀝🀞🀞🀟🀟🀠🀡"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.chinitsu]);
}

@("For a half flush, we get honitsu")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀀🀙🀙🀜🀝🀝🀞🀞🀟🀟🀠🀡"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.south, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.honitsu]);
}

@("If we only have terminals and honours, it is honroutou")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀀🀀🀁🀁🀃🀃🀇🀇🀐🀐🀙🀙🀡🀡"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.honroutou, Yaku.chiiToitsu]);
}

@("If we have at least one chi and terminals in all sets, it is junchan taiyai")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀐🀑🀒🀖🀗🀘🀟🀠🀡🀇🀇🀏🀏🀏"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.junchan]);
}

@("If we have only terminals (no chi), then it is not junchan")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀇🀇🀏🀏🀏🀐🀐🀐🀙🀙🀙🀡🀡🀡"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.not.contain([Yaku.junchan]);
}

@("No minipoints is a pinfu on a closed hand")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀐🀑🀒🀖🀗🀘🀜🀝🀞🀟🀠🀡🀇🀇"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.pinfu]);
}

@("An open hand is no pinfu")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀐🀑🀒🀖🀗🀘🀜🀝🀞🀟🀠🀡🀇🀇"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.length.should.equal(0);
}

@("A pair with value is no pinfu")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀐🀑🀒🀖🀗🀘🀜🀝🀞🀟🀠🀡🀀🀀"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.length.should.equal(0);
}

@("Not a two-sided wait is no pinfu")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀐🀑🀒🀖🀗🀘🀜🀝🀞🀟🀠🀡🀇🀇"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[1],
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.length.should.equal(0);
}

@("If the all sets contain a terminal or honour, and at least one chi is present, it is chanta")
unittest
{
    auto game = new Ingame(PlayerWinds.east, "🀆🀆🀇🀈🀉🀍🀎🀏🀐🀑🀒🀙🀙🀙"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[1],
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.chanta]);
}