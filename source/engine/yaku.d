module mahjong.engine.yaku;

import std.algorithm : all;
import mahjong.domain.enums;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.tile;
import mahjong.engine.mahjong;

enum Yaku {riichi, doubleRiichi, ippatsu, menzenTsumo, tanyao, pinfu, 
			iipeikou, sanShoukuDoujun, itsu, fanpai, chanta, rinshanKaihou, chanKan, haitei, 
            chiiToitsu, sanShokuDokou, sanAnkou, sanKanTsu, toiToiHou, honitsu, shouSangen, 
			honroutou, junchan, ryanPeikou, chinitsu, nagashiMangan,
            kokushiMusou, chuurenPooto, tenho, chiho, renho, suuAnkou, suuKanTsu, ryuuIisou, 
			chinrouto, tsuuIisou, daiSangen, shouSuushii, daiSuushii};

const(Yaku)[] determineYaku(const MahjongResult mahjongResult, const Ingame player, const Metagame metagame)
in
{
    assert(mahjongResult.isMahjong, "Yaku cannot be determined on a non mahjong hand");
}
body
{
	auto leadingWind = metagame.leadingWind;
	auto ownWind = player.wind;
	return [Yaku.riichi, Yaku.ippatsu, Yaku.menzenTsumo];
}

private const(Yaku)[] determineYaku(const MahjongResult mahjongResult, const Environment environment)
in
{
    assert(mahjongResult.isMahjong, "Yaku cannot be determined on a non mahjong hand");
}
body
{
    if(mahjongResult.isNagashiMangan)
    {
        return [Yaku.nagashiMangan];
    }
    Yaku[] yakus;
    yakus ~= determineRiichiRelatedYakus(environment);
    yakus ~= determineSituationalYaku(environment);
    yakus ~= determineWholeHandYaku(mahjongResult, environment);
    yakus ~= determinePonBasedYaku(mahjongResult, environment);
    return yakus;
}

@("If the player has no yaku, it should be recognised as such")
unittest
{
    import fluent.asserts;
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

private Yaku[] determineRiichiRelatedYakus(const Environment environment) pure
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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

private Yaku[] determineSituationalYaku(const Environment environment) pure
{
    Yaku[] yakus;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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

private Yaku[] determineWholeHandYaku(const MahjongResult mahjongResult, Environment environment)
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
    if(mahjongResult.hasAtLeastOneChi && mahjongResult.allSetsHaveATerminal)
    {
        yakus ~= Yaku.junchan;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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
    import fluent.asserts;
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

private Yaku[] determinePonBasedYaku(const MahjongResult result, Environment environment)
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

private struct Environment
{
    const PlayerWinds leadingWind;
    const PlayerWinds ownWind;
    const bool isRiichi;
    const bool isDoubleRiichi;
    const bool isFirstTurnAfterRiichi;
    const bool isSelfDraw;
    const bool isReplacementTileFromKan;
    const bool isKanSteal;
    const bool isClosedHand;
    const bool isLastTileBeforeExhaustiveDraw;
    const Tile lastTile;
}

private size_t countFanpai(const MahjongResult result, PlayerWinds leadingWind, PlayerWinds ownWind)
{
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
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀄🀄🀄"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(1);
}

@("Having a pair of dragons does not count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PairSet("🀄🀄"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(0);
}

@("Having a pon of simples does not count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀐🀐🀐"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(0);
}

@("Having a pon of own winds count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀂🀂🀂"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(1);
}

@("Having a pon of leading winds count as a fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀀🀀🀀"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(1);
}

@("Having a pon of winds which is not leading nor own is no fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀁🀁🀁"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.west).should.equal(0);
}

@("Having a pon of winds which is both leading and own count as two fanpai")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto result = MahjongResult(true, [new PonSet("🀀🀀🀀"d.convertToTiles)]);
    result.countFanpai(PlayerWinds.east, PlayerWinds.east).should.equal(2);
}

private size_t amountOfConsealedPons(const MahjongResult result)
{
    import std.algorithm : count;
    return result.sets.count!(s => s.isPon && !s.isOpen);
}

@("A consealed pon is counted as one")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto pon = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [pon]);
    result.amountOfConsealedPons.should.equal(1);
}

@("Multiple consealed pons are all counted")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto pon = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [pon, pon, pon]);
    result.amountOfConsealedPons.should.equal(3);
}

@("An open pon is not counted as a consealed pon")
unittest
{
    import fluent.asserts;
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
    import mahjong.engine.creation;
    auto pair = new PairSet("🀀🀀"d.convertToTiles);
    auto chi = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi]);
    result.amountOfConsealedPons.should.equal(0);
}

private size_t amountOfKans(const MahjongResult result)
{
    import std.algorithm : count;
    return result.sets.count!(s => s.isKan);
}

@("A kan is counted as one")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto kan = new PonSet("🀡🀡🀡🀡"d.convertToTiles);
    auto result = MahjongResult(true, [kan]);
    result.amountOfKans.should.equal(1);
}

@("Multiple kans are all counted")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto kan = new PonSet("🀡🀡🀡🀡"d.convertToTiles);
    auto result = MahjongResult(true, [kan, kan, kan]);
    result.amountOfKans.should.equal(3);
}

@("A simple pon is not counted as a kan")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto pon = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [pon]);
    result.amountOfKans.should.equal(0);
}

@("A pair or a chi is not counted as a kan")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    auto pair = new PairSet("🀀🀀"d.convertToTiles);
    auto chi = new ChiSet("🀓🀔🀕"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi]);
    result.amountOfKans.should.equal(0);
}

private bool isThreeLittleDragons(const MahjongResult result)
{
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
    import mahjong.engine.creation;
    auto pair = new PairSet("🀇🀇"d.convertToTiles);
    auto pon1 = new PonSet("🀌🀌🀌"d.convertToTiles);
    auto pon2 = new PonSet("🀗🀗🀗"d.convertToTiles);
    auto result = MahjongResult(true, [pair, pon1, pon2]);
    result.isThreeLittleDragons.should.equal(false);
}

bool hasPonInAllThreeSuits(const MahjongResult result)
{
    import std.algorithm : any;
    import std.conv : to;
    bool[Types][Numbers] stats;
    foreach(set; result.sets)
    {
        if(!set.isPon) continue;
        if(set.isSetOf(Types.dragon)) continue;
        if(set.isSetOf(Types.wind)) continue;
        auto number = set.tiles[0].value.to!Numbers;
        if(number !in stats)
        {
            stats[number] = (bool[Types]).init;
        }
        stats[number][set.tiles[0].type] = true;
    }
    return stats.byValue.any!(s => s.length == 3);
}

@("If I have the same pon in three suits, it should be recognized as such")
unittest
{
    import fluent.asserts;
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
    import mahjong.engine.creation;
    auto chars = new PonSet("🀇🀇🀇"d.convertToTiles);
    auto dragons = new PonSet("🀅🀅🀅"d.convertToTiles);
    auto winds = new PonSet("🀀🀀🀀"d.convertToTiles);
    auto result = MahjongResult(true, [chars, dragons, winds]);
    result.hasPonInAllThreeSuits.should.equal(false);
}

