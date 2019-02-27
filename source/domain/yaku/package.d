module mahjong.domain.yaku;

import mahjong.domain.enums;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.tile;
import mahjong.domain.result;
import mahjong.domain.yaku.chi;
import mahjong.domain.yaku.environment;
import mahjong.domain.yaku.hand;
import mahjong.domain.yaku.pon;
import mahjong.domain.yaku.riichi;
import mahjong.domain.yaku.situational;
import mahjong.domain.yaku.yakuman;

enum Yaku {riichi, doubleRiichi, ippatsu, menzenTsumo, tanyao, pinfu, 
    iipeikou, sanShoukuDoujun, itsu, fanpai, chanta, rinshanKaihou, chanKan, haitei, 
    chiiToitsu, sanShokuDokou, sanAnkou, sanKanTsu, toiToiHou, honitsu, shouSangen, 
    honroutou, junchan, ryanPeikou, chinitsu, nagashiMangan,
    kokushiMusou, chuurenPooto, tenho, chiho, renho, suuAnkou, suuKanTsu, ryuuIisou, 
    chinrouto, tsuuIisou, daiSangen, shouSuushii, daiSuushii}

const(Yaku)[] determineYaku(const MahjongResult mahjongResult, const Ingame player, const Metagame metagame)
in
{
    assert(mahjongResult.isMahjong, "Yaku cannot be determined on a non mahjong hand");
}
do
{
    auto leadingWind = metagame.leadingWind;
    auto ownWind = player.wind;
    return [Yaku.riichi, Yaku.ippatsu, Yaku.menzenTsumo];
}

// This function should be private. But to have a unittest for each yaku serve as 
// the negative for the other yakus, we make this function package-private.
package const(Yaku)[] determineYaku(const MahjongResult mahjongResult, const Environment environment)
    in
{
    assert(mahjongResult.isMahjong, "Yaku cannot be determined on a non mahjong hand");
}
body
{
    import std.array : empty;
    if(mahjongResult.isNagashiMangan)
    {
        return [Yaku.nagashiMangan];
    }
    Yaku[] yakus = determineYakuman(mahjongResult, environment);
    if(!yakus.empty) 
    {
        return yakus;
    }
    yakus ~= determineRiichiRelatedYakus(environment);
    yakus ~= determineSituationalYaku(environment);
    yakus ~= determineWholeHandYaku(mahjongResult, environment);
    yakus ~= determinePonBasedYaku(mahjongResult, environment);
    yakus ~= determineChiBasedYaku(mahjongResult, environment.isClosedHand);
    return yakus;
}

@("If the player has no yaku, it should be recognised as such")
unittest
{
    import fluent.asserts;
    import mahjong.engine.mahjong;
    auto game = new Ingame(PlayerWinds.west, "🀙🀙🀙🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
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
    yaku.length.should.equal(0);
}

@("Nagashi mangan should be short-circuited")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    auto result = MahjongResult(true, [new NagashiManganSet]); 
    Environment env = {
    leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            isRiichi: false,
            isSelfDraw: false,
            isClosedHand: true
    };
    auto yaku = determineYaku(result, env);
    yaku.should.equal([Yaku.nagashiMangan]);
}

size_t convertToFan(const Yaku yaku, bool isClosedHand) pure
{
    final switch(yaku) with(Yaku)
    {
        case riichi, ippatsu, menzenTsumo, tanyao, pinfu, iipeikou, 
            fanpai, rinshanKaihou, chanKan, haitei:
            return 1;
        case sanShoukuDoujun, itsu, chanta:
            // One fan and one extra for a closed hand.
            return isClosedHand ? 2 : 1;
            case doubleRiichi, chiiToitsu, sanShokuDokou, sanAnkou, sanKanTsu, 
                toiToiHou, shouSangen, honroutou:
                return 2;
        case honitsu, junchan:
            // Two fan and one extra for a closed hand.
            return isClosedHand ? 3 : 2;
        case ryanPeikou:
            return 3;
        case nagashiMangan:
            return 5;
        case chinitsu:
            // Five fan and one extra for a closed hand.
            return isClosedHand ? 6 : 5;
            case kokushiMusou, chuurenPooto, tenho, chiho, renho, suuAnkou, 
                suuKanTsu, ryuuIisou, chinrouto, tsuuIisou, daiSangen, shouSuushii:
                return 13;
        case daiSuushii:
            return 26;
    }
}