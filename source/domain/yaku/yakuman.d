module mahjong.domain.yaku.yakuman;

import mahjong.domain.result;
import mahjong.domain.yaku;
import mahjong.domain.yaku.environment;

version(unittest)
{
    import fluent.asserts;
    import mahjong.domain.enums;
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