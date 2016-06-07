module mahjong.engine.yaku;

import std.stdio;
import std.string;
import std.range;
import std.uni;
import std.algorithm;
import std.random;
import std.process;
import std.conv;
import std.file;

import enumlist; 
import mahjong.domain.tile;

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
    { return enumlist.yakus.uhan; }
  
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
