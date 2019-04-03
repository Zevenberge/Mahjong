module mahjong.domain.yaku.riichi;

import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.enums;
    import mahjong.domain.ingame;
    import mahjong.engine.mahjong;
}

package Yaku[] determineRiichiRelatedYakus(const Environment environment) pure
{
    if(environment.isRiichi)
    {
        Yaku[] yakus;
        if(environment.isDoubleRiichi)
        {
            yakus ~= Yaku.doubleRiichi;
        }
        else
        {
            yakus ~= Yaku.riichi;
        }
        if(environment.isFirstTurnAfterRiichi)
        {
            yakus ~= Yaku.ippatsu;
        }
        return yakus;
    }
    else
    {
        return null;
    }
}

@("If the player is riichi, the yaku riichi should be granted")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: true,
            isSelfDraw: false,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.riichi]);
}

@("If the player is double riichi, the yaku double riichi should be granted")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: true,
            isDoubleRiichi: true,
            isSelfDraw: false,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.doubleRiichi]);
}

@("If the player finished within one round of their riichi declaration, they get the ippatsu yaku")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: true,
            isSelfDraw: false,
            isFirstTurnAfterRiichi: true,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.riichi, Yaku.ippatsu]);
}