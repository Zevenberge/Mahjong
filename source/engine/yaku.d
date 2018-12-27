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
    yakus ~= determineWholeHandYaku(mahjongResult, environment.isClosedHand);
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
    yaku.should.equal([Yaku.menzenTsumo, Yaku.rinshanKaihou]);
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

private Yaku[] determineWholeHandYaku(const MahjongResult mahjongResult, bool isClosedHand)
{
    Yaku[] yakus;
    if(isClosedHand && mahjongResult.tiles.all!(t => t.isSimple))
    {
        yakus ~= Yaku.tanyao;
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

/+
enum yakus {iihan = 1, ryanan = 2, sanhan = 3, uhan = 5, yakuman = 13, double_yakuman = 26};
class yaku
{ 

  size_t[hands.max+1] occurences = 0;

  int amountOfYaku(const Tile[] closed_hand, const Tile[] open_hand, const Tile final_tile, bool isNagashiMangan, bool isRiichi, bool isDoubleRiichi = false)
  in
  { int open_tiles = to!int(open_hand.length);
    bool isGood = true;
    switch(open_tiles)
    {  case 0,3,4,6,7,8,9,10,11,12,13,14,15,16:
         isGood = true;
         break;
       case 1,2,5:
         isGood = false;
         break;
       default:
         isGood = false;
         break;
    }
    assert(isGood);
  }
  body
  { /*
      This function checks the amount of yakus. The amount of doras will be checked in a different function.
    */
    if(isNagashiMangan)  // Nagashi mangan is the special case.
    { return yakus.uhan; }
  
    bool isOpen = false;
    if(open_hand.length > 0)
    {isOpen = true;  }
   
    int yaku = 0; // Amount of yaku.
  
    yaku += amountOfYakuman();
    if(yaku > 0) {return yaku;}  // When we have found one or more yakuman, then the yakucheck stops.
  
    yaku += amountOfClosedYaku(isOpen);
    yaku += amountOfOpenYaku();
    return yaku;
  }
  int amountOfClosedYaku(const bool isOpen)
  {
    int yaku = 0;
    // Initialise the conflicting hands.
    bool chiitoitsu = false; // Seven pairs
    bool ryanpeikou = false; // Two times two identical chis.
  
    if(!isOpen) { // The requirement is that all tiles be closed.
  // yaku += isRiichi(); // Not only riichi but also double riichi and ippatsu.
  // yaku += isTsumo(); // Tsumo
  // yaku += isRyanpeikou(); // Two times two identical chis
         if(!ryanpeikou){}  // Ryanpeikou is worth more than Chiitoitsu and should therefore get priority.
  //         { yaku += isChiiToitsu(); } // Seven pairs
         if(!chiitoitsu){}
  {   // Some yaku are excluded if the hand is seven pairs, which are not yet mutually exclusive (e.g. seven pairs and pinfu).
  // yaku += isTanyao(); // All simples
  // yaku += isPinfu(); // No minipoints
                if(!chiitoitsu){}
  // { yaku += isIipeikou(); }// Two identical chis
  }
    }
    return yaku;
  }
  int amountOfOpenYaku()
  {
    int yaku = 0;
    // Initialise the conflicting hands.
    bool chinitsu = false;
    bool junchan = false;
   
  // yaku += isChinitsu  // Flush
        if(!chinitsu) {}
  //     {yaku += isHonitsu(); } // Half flush
  // yaku += isJunchan(); // Terminals in every set, contains a chi.
        if(!junchan) {}
  //     {yaku += isChanta(); // Honours and terminals in every set, contains no chi.
  // yaku += isHonroutou(); // Only honours and terminals, therefore not containing a chi.
  // yaku += isShousangen(); // Three little dragons (kawaii).
  // yaku += isToitoihou(); // All pons.
  // yaku += isSankantsu(); // Three kans. 
  // yaku += isSanankou(); // Three closed pons.
  // yaku += isSanshokudokou(); // Three identical pons in three different sets.
  // yaku += isHaitei(); // Final tile of the wall.
  // yaku += isChankan(); // Kan robbery.
  // yaku += isRinshankaihou(); // Mahjong with the replacement tile of a kan.
  // yaku += isFanpai(); // Pon of dragons / leading wind / own wind - can count multiple times.
  // yaku += isItsu(); // 1-2-3, 4-5-6, 7-8-9 in one suit.
  // yaku += isSanshokudoujun(); // Identical chis in every suit.
    return yaku;
  }
  int amountOfYakuman()
  {
     int yaku = 0;
     bool isOpen;
     // Initialise the conflicting hands.
     bool daisuushii = false;
     
     if(!isOpen) {
  // yaku += isKakushimusou(); // Thirteen orphans.
  // yaku += isTenho(); // Blessings - Mahjong in the first round.
  // yaku += isChuurenpooto(); // Nine gates.
  // yaku += isSuuankou(); // Four consealed pons (tsumo or pair wait).
  }
  // yaku += isDaisuushii(); // Big four winds.
        if(!daisuushii) {}
  // {yaku += isShousuushii(); }// Small four winds.
  // yaku += isDaisangen(); // Three big dragons.
  // yaku += Tsuuiisou(); // Honours only.
  // yaku += Chinrouto(); // Terminals only.
  // yaku += Ryuuiisou(); // All greens.
  // yaku += Suukantsu(); // Four kans.
  
     return yaku;
    }
}
+/