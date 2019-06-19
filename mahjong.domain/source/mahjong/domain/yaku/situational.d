module mahjong.domain.yaku.situational;

import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;
import mahjong.util.collections;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.enums;
    import mahjong.domain.ingame;
    import mahjong.domain.mahjong;
}

private alias Yakus = NoGcArray!(4, Yaku);

package Yakus determineSituationalYaku(ref const Environment environment) @safe pure @nogc nothrow
{
    Yakus yakus;
    if(environment.isClosedHand && environment.isSelfDraw)
    {
        yakus ~= Yaku.menzenTsumo;
    }
    if(environment.isReplacementTileFromKan)
    {
        yakus ~= Yaku.rinshanKaihou;
    }
    if(environment.isKanSteal)
    {
        yakus ~= Yaku.chanKan;
    }
    if(environment.isLastTileBeforeExhaustiveDraw)
    {
        yakus ~= Yaku.haitei;
    }
    return yakus;
}

@("If the player draws their final tile, the yaku menzen tsumo is awarded")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isSelfDraw: true,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.menzenTsumo]);
}

@("If the player is open while they get a kan replacement, they are rinchan kaihou")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isSelfDraw: true,
            isReplacementTileFromKan: true,
            isClosedHand: false
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.rinshanKaihou]);
}

@("If the player draws their final tile as a kan replacement, it is both tsumo and rinchan kaihou")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isSelfDraw: true,
            isReplacementTileFromKan: true,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.containOnly([Yaku.menzenTsumo, Yaku.rinshanKaihou]);
}

@("Robbing a kong results in chan kan")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isKanSteal: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.chanKan]);
}

@("Salvaging the last tile is a haitei")
unittest
{
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0],
            isRiichi: false,
            isLastTileBeforeExhaustiveDraw: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.haitei]);
}