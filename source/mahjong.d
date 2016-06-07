module mahjong;

//import std.c.stdio;
import std.stdio;
import std.string;
import std.range;
import std.uni;
import std.algorithm;
import std.random;
import std.process;
import std.conv; 
import std.file;
// TODO: prune the import list


import enumlist; // File that contains all of the enum constants.
import objects; // File that contains all of the structs/classes.
import yakus; // File that contains the functions that calculate the amount of yaku.
import tile_mod;

import dsfml.graphics;

/*void getWallSprites(ref Tile[] wall, ref Texture tilesTexture)
{
  foreach(tile; wall)
  {
    tile.getSprite(tilesTexture);
  }
}

void setUpWall(ref Tile[] wall, ref Texture tilesTexture, const int gameMode)
{
   initialiseWall(wall, gameMode);
   give_IDs(wall);
   getWallSprites(wall, tilesTexture);
   shuffle_wall(wall);
}

void initialiseWall(ref Tile[] wall, const int gameMode)
{
  switch(gameMode)
  {
     case GameMode.Bamboo:
       initialiseBambooWall(wall);
       break;
     default:
       initialiseNormalWall(wall);
       break;
  } 
}

void initialiseBambooWall(ref Tile[] wall)
{
   for(int j = bamboos.min; j <= bamboos.max; ++j)
   {
      for(int i = 0; i < 4; ++i)
      {
        wall ~= new Tile(types.bamboo, j);
      }
   }
}

void initialiseNormalWall(ref Tile[] wall)
{ // FIXME: Remove the dependence on the 'legacy' functions and rebuild them nicely.
  // TODO: Use enumloop hax to get the whole wall.
   set_up_wall(wall);
}*/

void set_up_wall(ref Tile[] wall, int dups = 4)
{
   for(int i = 0; i < dups; ++i)
   {
     initialise_wall(wall);
   }
 //  give_IDs(wall);
   define_doras(wall);
 //  shuffle_wall(wall);
}

void initialise_wall(ref Tile[] wall) //Optionally change the amount of duplicates in the wall.
{
   /*
     This subroutine will initialise the wall with the standard set of mahjong tiles. It does not take into account doras.
   */
   
   dchar[] tiles = define_tiles(); // First load all mahjong tiles.
   label_tiles(wall, tiles);
}

void label_tiles(ref Tile[] tiles, dchar[] faces)
{
   foreach(stone; stride(faces,1))
   {
     int stonevalue; 
     int stonetype = get_type(stone, stonevalue);
     auto tile = new Tile;
     tile.face = stone;
     tile.type = stonetype;
     tile.value = stonevalue;
     tiles ~= tile;
   }
   
}

void give_IDs(ref Tile[] wall)
{
  size_t ID = 0;
  foreach(tile; wall)
  {
    tile.ID = ID;
    ++ID;
  }
}

void define_doras(ref Tile[] wall)
in
{
  assert(wall.length == 136);
}
  /*
    Define the doras that are in the wall. The way this is programmed, this has to be initialised before the shuffle. It is put in a seperate subroutine to allow for multiple dora definitions.
  */
body
{
  ++wall[44].dora;
  ++wall[80].dora;
  ++wall[116].dora;
}


dchar[] define_tiles()
{
  /*
    Define the tiles in the wall. For now, use the mahjong tiles provided by the unicode set.
  */
   dchar[] tiles;
   tiles ~= "🀀🀁🀂🀃🀅🀄🀆🀇🀈🀉🀊🀋🀌🀍🀎🀏🀐🀑🀒🀓🀔🀕🀖🀗🀘🀙🀚🀛🀜🀝🀞🀟🀠🀡"d;
   return tiles;
  /* Set of Mahjong tiles in Unicode format
🀀 	🀁 	🀂 	🀃 	🀄 	🀅 	🀆 	🀇 	🀈 	🀉 	🀊 	🀋 	🀌 	🀍 	🀎 	🀏
🀐 	🀑 	🀒 	🀓 	🀔 	🀕 	🀖 	🀗 	🀘 	🀙 	🀚 	🀛 	🀜 	🀝 	🀞 	🀟
🀠 	🀡 	🀢 	🀣 	🀤 	🀥 	🀦 	🀧 	🀨 	🀩 	🀪 	🀫
 */
}


int get_type(dchar stone, out int value)
{
   dchar[] tiles = define_tiles(); // Always load the default tile set such that the correct characters are compared!!
   int tile_number=0;
   int typeOfTile;
   foreach(face; stride(tiles,1))
   {
     if(stone == face)
     {
      switch (tile_number) {
      case 0: .. case 3:
            typeOfTile = types.wind;
            value = tile_number;
            break;
      case 4: .. case 6:
            typeOfTile = types.dragon;
            value = tile_number - 4;
            break;
      case 7: .. case 15:
            typeOfTile = types.character;
            value = tile_number - 7;
            break;
      case 16: .. case 24:
            typeOfTile = types.bamboo;
            value = tile_number - 16;
            break;
      case 25: .. case 33:
            typeOfTile = types.ball;
            value = tile_number - 25;
            break;
      default:
            typeOfTile = -1;
            value = -1;
            break;

      }
      break;
     }
     ++tile_number;
   }
   return typeOfTile;
}
unittest{
 writeln("Checking the labelling of the wall...");
 Tile[] wall;
 set_up_wall(wall);
 foreach(stone; wall)
 {
   if (stone.face==  '🀀')
   {  assert(stone.type==types.wind);
      assert(stone.value==winds.east);
   } else if (stone.face == '🀏')
   {  assert(stone.type==types.character);
      assert(stone.value==characters.nine);
   }
 }
 writeln(" The tiles are correctly labelled.");
}

void shuffle_wall(ref Tile[] wall)
  /*
   Shuffle the tiles in the wall. Take a slice off the middle of the wall and place it at the end.
  */
in
{
  assert(wall.length > 0);
}
body
{
  for(int i=0; i<500; ++i)
  {
    ulong t1 = uniform(0, wall.length);
    ulong t2 = uniform(0, wall.length);
    swap_tiles(wall[t1],wall[t2]);
  }
}

bool is_equal(const bool exprA, const bool exprB)
{
  if( exprA && exprB) { return true;}
  if( !exprA && !exprB) {return true;}
  return false;
}
unittest{
 writeln("Checking the is_equal function for bools...");
 assert(is_equal(true,true));
 assert(is_equal(false,false));
 assert(!is_equal(false,true));
 assert(!is_equal(true,false));
}
bool is_equal(const Tile tileA, const Tile tileB)
{
  if((tileA.type == tileB.type) && (tileA.value == tileB.value))
  { return true; } else { return false;}
/*  assert(false);
  return false;*/
}
unittest{
 writeln("Checking the is_equal function for tiles...");
 Tile[] wall;
 set_up_wall(wall);
 int i = uniform(0, to!int(wall.length));
 assert(is_equal(wall[i], wall[i]));
 writeln(" The is_equal function is correct.");
}

bool is_identical(const ref Tile tileA, const ref Tile tileB)
{
  if((tileA.ID == tileB.ID) && is_equal(tileA,tileB))
  {
    return true;
  }
  else
  {
    return false;
  }
}

bool is_constructive(const Tile tileA, const Tile tileB)
{
  if((tileA.type == tileB.type) && (tileA.value == tileB.value - 1))
  { return true; } else { return false;}
/*  assert(false);
  return false;*/
}
unittest{
 writeln("Checking the is_constructive function...");
 Tile[] wall;
 set_up_wall(wall);
 int i = uniform(0, to!int(wall.length));
 Tile tiledup = wall[i];
 ++tiledup.value;
 assert(is_constructive(wall[i], tiledup));
 assert(!is_constructive(wall[i], wall[i]));
 writeln(" The is_constructive function is correct.");
}

bool scan_hand(Tile[] hand, int chis = 0, int pons = 0, int pairs = 0)
in {assert(hand.length > 0);}
out {assert(hand.length > 0);}
body{ /*
    See if the current hand is a legit mahjong hand.
      */
  sort_hand(hand);
  bool is_mahjong=false;
  // Run a dedicated scan for the weird hands, like Thirteen Orphans and Seven pairs, but only if the hand has exactly 14 tiles.
  if(hand.length == 14) 
  {
    if(is_seven_pairs(hand) || is_thirteen_orphans(hand))
    { 
        is_mahjong = true;
       return is_mahjong;
    }
  }
  Tile[] mahjong_hand;
 /*
  int chis = 0; // Amount of pons in the hand.
  int pons = 0; // Amount of chis in the hand.
  int pairs = 0; // Amount of pairs in the hand.
 */

  //  Check the regular hands.
  is_mahjong = scan_mahjong(hand, mahjong_hand, chis, pairs, pons);
  return is_mahjong;
}

bool is_seven_pairs(const Tile[] hand)
in
{ assert(hand.length == 14);}
body
{ /* 
    This subroutine checks if the hand forms seven pairs. Nothing more, nothing less.
  */
  for(int i=0; i<7; ++i)
  {
    if(hand.length > 2*i+2) 
    { // Check if no two pairs are the same, only if the hand size allows it.
       if(is_equal(hand[2*i],hand[2*i+2]))
       { 
          return false;
       } // Return if we have three identical tiles.
    }
    if(!is_equal(hand[2*i],hand[2*i+1]))
    { // Check whether is is a pair.
      return false;
    }  // If it is no pair, it is no seven pairs hand.
  }
  return true;
}
bool is_thirteen_orphans(const Tile[] hand)
in
{ assert(hand.length == 14);}
body
{ /*
    This subroutine checks if the hand has thirteen orphans in them.
  */
  int pairs = 0;
  
  for(int i = 0; i < 13; ++i)
  { 
    auto honour = new Tile;
    
    switch(i){
    case 0: .. case 3: // Winds
         honour.type = types.wind;
         honour.value = i;
         break;
    case 4: .. case 6: // Dragons
         honour.type = types.dragon;
         honour.value = i % (winds.max + 1);
         break;
    case 7, 8:         // Characters
         honour.type = types.character;
         honour.value = isOdd(i) ? characters.one : characters.nine;
         break;
    case 9, 10:        // Bamboos
         honour.type = types.bamboo;
         honour.value = isOdd(i) ? bamboos.one : bamboos.nine;
         break;
    case 11, 12:       // Balls
         honour.type = types.ball;
         honour.value = isOdd(i) ? balls.one : balls.nine;
         break;
    default:
         assert(false);
    }
    if(!is_equal(hand[i+pairs], honour)) //If the tile is not the honour we are looking for
    { 
      return false;  
    }
    if((i + pairs + 1) < hand.length) 
    {
        if(is_equal(hand[i+pairs], hand[i+pairs+1])) // If we have a pair
        {
             ++pairs;
             if(pairs > 1)
             {
               return false;
             }  // If we have more than one pair, it is not thirteen orphans.
        }
    }
  }
  /*
    When the code arrives at this point, we have confirmed that the hand has each of the thirteen orphans in it. The final check is whether the hand also has the pair.
  */
  if(pairs == 1) { return true; }
  
  return false;
}
bool scan_mahjong(ref Tile[] hand, ref Tile[] mahjong_hand, ref int chis, ref int pairs, ref int pons)
{ /*
     This subroutine checks whether the hand at hand is a mahjong hand. It does - most explicitely- NOT take into account yakus. The subroutine brute-forces the possible combinations. It first checks if the first two tiles form a pair (max. 1). Then it checks if the first three tiles form a pon. If it fails, it returns a false.

pairs --- pons  --- chis                <- finds a pair
       +- pons  --- chis                <- finds a pon
                 +- pons  -- chis       <- finds nothing and returns to the previous layer, in which it can still find a chi.

  */
  bool is_set = false;
  bool is_mahjong = false;
  Tile[] temphand = hand.dup;
  Tile[] tempmahj = mahjong_hand.dup;
  if(pairs < 1)
  { // Check if there is a pair, but only if there is not yet a pair.
    is_set = scan_equals(temphand, tempmahj, pairs, set.pair);
    is_mahjong = scan_progression(hand, temphand, mahjong_hand, tempmahj, chis, pairs, pons, is_set);
    if(is_mahjong) {
    return is_mahjong;
    } else {
    assert(!is_mahjong); 
    if(is_set) {
    --pairs;}} // Decrease the amount of pairs by one if this is not the solution.
  }

  temphand = hand.dup;
  tempmahj = mahjong_hand.dup;
    // Check if there is a pon.
    is_set = scan_equals(temphand, tempmahj, pons, set.pon);
    is_mahjong = scan_progression(hand, temphand, mahjong_hand, tempmahj, chis, pairs, pons, is_set);
    if(is_mahjong) {
    return is_mahjong;
    } else { 
    assert(!is_mahjong); 
    if(is_set) {
    --pons;}} // Decrease the amount of pons by one if this is not the solution.

  temphand = hand.dup;
  tempmahj = mahjong_hand.dup;
    // Check if there is a chi.
    is_set = scan_chis(temphand, tempmahj, chis);
    is_mahjong = scan_progression(hand, temphand, mahjong_hand, tempmahj, chis, pairs, pons, is_set);
    if(is_mahjong) {
    return is_mahjong;
    } else {
    assert(!is_mahjong); 
    if(is_set) {
    --chis;}} // Decrease the amount of pons by one if this is not the solution.
  return is_mahjong;
}
bool scan_progression(ref Tile[] hand, ref Tile[] temphand, ref Tile[] mahjong_hand, ref Tile[] tempmahj, ref int chis, ref int pairs, ref int pons, bool is_set)
{   /* 
      Check whether the mahjong check can advance to the next stage.
    */

    bool is_mahjong = false;
 if(is_set)
 {
    int amountOfSets = chis + pons;
    if((amountOfSets == 4) && (pairs == 1))
    { is_mahjong = true;
      hand = tempmahj.dup;
      mahjong_hand = tempmahj.dup;
 //writeln();
      return is_mahjong;
    } else {
    is_mahjong = scan_mahjong(temphand, tempmahj, chis, pairs, pons);
       if(is_mahjong){
       hand = temphand.dup;
       mahjong_hand = tempmahj.dup;
       }
    } 
 }
    return is_mahjong;
}
bool scan_chis(ref Tile[] hand, ref Tile[] final_hand, ref int chis)
{ /*
     This subroutine checks whether there is a chi hidden in the beginning of the hand. It should also take into account that there could be doubles, i.e. 1-2-2-2-3. Subtract the chi from the initial hand.
  */
  if(hand[0].type < types.character)  // If the tile is a wind or a dragon, then abort the function.
  { return false; }

  Tile[] mutehand = hand.dup; // Create a back-up of the hand that can be mutated at will.
  Tile[] mutefinal;       // Create a temporary array that collects the chi.
  mutefinal ~= mutehand[0];
  mutehand = mutehand[1 .. $]; // Subtract the tile from the hand.

  for(int i=0;(i < 5) && (i < mutehand.length);++i)
  { 
    if(is_constructive(mutefinal[$-1], mutehand[i]))
    {
      take_out_tile(mutehand, mutefinal, i); // The second tile in a row
      for( ; (i < 10) && (i < mutehand.length); ++i)
      {
        if(is_constructive(mutefinal[$-1], mutehand[i]))
        {
           take_out_tile(mutehand, mutefinal, i); // The chi is completed.
           assert(mutefinal.length == 3);
           assert(hand.length == mutefinal.length + mutehand.length);
           
           hand = mutehand.dup; // Now that the chi is confirmed, the hand can be reduced.
           final_hand ~= mutefinal; // Add the chi to the winning hand.
           ++chis;
           return true;
        }
      }

      break;
    }
  }
  
  return false; // Do not return the modifications to the hand.
}
void take_out_tile(ref Tile[] hand, ref Tile[] output, Tile takenOut)
{
   int i = 0;
   foreach(tile; hand)
   {
     if(is_identical(tile, takenOut))
     {
       take_out_tile(hand, output, i);
       return;
     }
     ++i;
   }
   throw new Exception("Tile not found");
}
void take_out_tile(ref Tile[] hand, ref Tile[] output, const size_t i, size_t j = 0)
{
      if (i >= j)
      {
          j = i + 1;
      }
      Tile[] temphand;
      output ~= hand[i .. j];
      temphand ~= hand[j .. $];
      hand = hand[0 .. i];
      hand ~= temphand;
}
unittest // Check the take_out_tile function.
{
   writeln("Checking the take_out_tile function...");
   Tile[] wall, output;
   initialise_wall(wall,1); // Set up the "wall", which will act as our hand.
   Tile[] walldup = wall.dup;
   int i = uniform(0,to!int(wall.length));
   take_out_tile(wall, output, i);
   assert(output[0].type == walldup[i].type); // Check whether the tile that is taken out of the
   assert(output[0].value == walldup[i].value); // wall is actually the one that was intended.
   assert(wall.length == walldup.length-1);  // Also check if there is indeed a tile taken from the wall.
   wall ~= output;
   sort_hand(wall);
   assert(wall == walldup); // After adding the tile back to the wall, it should be complete again.

   // Add a second test for the overload.
   int j = uniform(i,to!int(wall.length));
   take_out_tile(wall, output, i, j);
   int k;
   for(i; i < j; ++i)
   {
     assert(is_equal(output[k],wall_dup[i]));
     ++k;
   }

   writeln(" The take_out_tile function is correct.");
}
bool scan_equals(ref Tile[] hand, ref Tile[] final_hand,  ref int pairs, const int distance)
{ /* distance = set.pair or set.pon
    This subroutine checks if the first few tiles form a set and then subtracts them from the inititial hand.
  */
if(hand.length > distance)
{ 
  if(!is_equal(hand[0],hand[distance])) 
  {return false;}
  
  final_hand ~= hand[0 .. distance+1];
  hand = hand[distance+1 .. $];
  ++pairs;
  return true;
} else { return false;}
}
unittest // Check whether the example hands are seen as mahjong hands.
{
   writeln("Checking the example hands...");
   test_hands("nine_gates", true);
   test_hands("example_hands", true);
   test_hands("unlegit_hands", false);
   writeln(" The function reads the example hands correctly.");

}
void test_hands(string filename, const bool is_hand)
{
  for( int line_number = 1; ; ++line_number)
{   Tile[] hand;
   dchar[] hand_faces;
   readline(filename, hand_faces, line_number);
   if(hand_faces.length != 14) {break;}
   label_tiles(hand, hand_faces);
   sort_hand(hand);
   bool is_mahjong;
   is_mahjong = scan_hand(hand);
   assert(is_equal(is_mahjong, is_hand));
   write("The mahjong is ", is_mahjong, ".  ");
   foreach(stone; hand) {write(stone);}
   writeln();
}
   writeln();

}

void sort_hand(ref Tile[] hand)
{  /*
    Sort the tiles in the hand. Arrange them by their type and their value.
   */
   for( ; ; )
   {
     Tile[] hand_prev = hand.dup;
     for(int i = 1; i < hand.length; ++i)
     {  // Sort by type first (dragon, wind, character, bamboo, ball)
       if(hand[i].type < hand[i-1].type) {
         swap_tiles(hand[i], hand[i-1]);
       } else if(hand[i].type == hand[i-1].type) {
          // Then sort them by value.
          if(hand[i].value < hand[i-1].value)
         { swap_tiles(hand[i], hand[i-1]);
         } else if(hand[i].value == hand[i-1].value)
          { if(hand[i].dora > hand[i-1].dora)
         { swap_tiles(hand[i], hand[i-1]);}
          }
       }
     }
     if(hand_prev == hand)
     {
      break;
     }
   }
}

void toggle(ref bool foo)
{
   foo = !foo;
}
unittest
{
  bool foo = true;
  toggle(foo); // foo is now false.
  assert(!foo);
  toggle(foo); // foo is again true.
  assert(foo);
}

void swap_tiles(ref Tile tileA, ref Tile tileB)
{
   Tile tileC = tileA;
   tileA = tileB;
   tileB = tileC;
}
unittest
{
  Tile tileA = Tile('p',1,2,3);
  Tile tileB = Tile('c',4,5,6);
  Tile tileAdup = tileA;
  Tile tileBdup = tileB;
  swap_tiles(tileA,tileB);
  assert(tileA == tileBdup);
  assert(tileB == tileAdup);

}

void readline(string filename, ref dchar[] output, int line_number)
{ /*
     Read a line from a file in dchar[] format. For example, read the example hands for unit testing.
  */
  assert(line_number > 0);
  if(exists(filename))
 { 
  int i=1;
  File file = File(filename,"r");
  while(!file.eof())
{
  string line = chomp(file.readln());
  if (line_number == i)
  { foreach(face; stride(line,1)){
     output ~= face;
    }
   break;
  }
  i++;
}
  if (line_number > i)
  { writeln("The file is not that large."); }
 } else {
   throw new Exception("The file does not exist.");
 }
}

void print_tiles(Tile[] wall)
{
   for(int i=0; i<5; ++i)
   {
     switch (cast(types)wall[i].type){
        case types.dragon:
        writeln(wall[i].face, " is a ", cast(types)wall[i].type, " with value ", cast(dragons)wall[i].value, ".");
        break;
        case types.wind:
        writeln(wall[i].face, " is a ", cast(types)wall[i].type, " with value ", cast(winds)wall[i].value, ".");
        break;
        default:
        writeln(wall[i].face, " is a ", cast(types)wall[i].type, " with value ", wall[i].value+1, ".");
     }
   }
}

bool isOdd(const int i)
in{ assert(i >= 0); }
body{ if( (i % 2) == 0){
  return false;}
  if( (i % 2) == 1){
  return true;}
  assert(true);
  return false;
}
unittest{
assert(isOdd(9));
assert(!isOdd(8));
}

bool isHonour(const ref Tile tile)
{
  if(tile.type < types.character)
  {
    return true;
  }
  else
  {
    return false;
  }
}
unittest
{
  auto tile = new Tile;
  tile.type = types.wind;
  assert(isHonour(tile));
  tile.type = types.dragon;
  assert(isHonour(tile));
  tile.type = types.character;
  assert(!isHonour(tile));
  tile.type = types.bamboo;
  assert(!isHonour(tile));
  tile.type = types.ball;
  assert(!isHonour(tile));
}

bool isTerminal(Tile tile)
{
  if(tile.type > types.dragon)
  {
    if((tile.value == characters.one) || (tile.value == characters.nine))
    {
      return true;
    }
  }
  return false;
}
unittest
{
  auto tile = new Tile;
  tile.type = types.character;
  tile.value = characters.one;
  assert(isTerminal(tile));
  tile.value = characters.two;
  assert(!isTerminal(tile));
  tile.value = characters.three;
  assert(!isTerminal(tile));
  tile.value = characters.four;
  assert(!isTerminal(tile));
  tile.value = characters.five;
  assert(!isTerminal(tile));
  tile.value = characters.six;
  assert(!isTerminal(tile));
  tile.value = characters.seven;
  assert(!isTerminal(tile));
  tile.value = characters.eight;
  assert(!isTerminal(tile));
  tile.value = characters.nine;
  assert(isTerminal(tile));
  tile.type = types.wind;
  tile.value = winds.east;
  assert(!isTerminal(tile));
  tile.type = types.dragon;
  tile.value = dragons.green;
  assert(!isTerminal(tile));
}

bool isIn(const Tile wanted, const Tile[] deck)
{
   foreach(tile; deck)
     if(is_equal(tile, wanted))
        return true;
   return false;
}

bool isIn(const int wanted, const int[] list)
{
   foreach(number; list)
     if(number == wanted)
        return true;
   return false;
}

// FIXME: Depreciated: use UFCS.
bool isIn(const ref Tile[] deck, const ref Tile wanted)
{
  foreach(tile; deck)
  {
    if(is_equal(tile, wanted))
    {
      return true;
    }
  }
  return false;
}
bool isAnotherIn(const ref Tile[] deck, const ref Tile wanted)
{
  foreach(tile; deck)
  {
    if(is_equal(tile, wanted) && !is_identical(tile, wanted))
    {
      return true;
    }
  }
  return false;
}

bool isConnected(const ref Tile[] hand, const ref Tile tile)
{
  bool connected = false;
  auto connection = new Tile;
  connection.type = tile.type;

  if(!isHonour(tile))
  { // See whether a tile within range 2 of the same suit is in the hand.
    for(connection.value = tile.value-2; connection.value <= tile.value+2; ++connection.value)
    {
      if(connection.value == tile.value)
      { // Skip the original value, as it requires an extra step.
        ++connection.value;
      }
      if(isIn(hand, connection))
      {
        connected = true;
        return connected;
      }
    } 
  }

  if(isAnotherIn(hand, tile))
  {
    connected = true;
    return connected;
  }
  else
  {
    connected = false;
    return connected;
  }
}

void message(const dchar[] mail)
{ // Write a message to the desired output.
  writeln(mail);
}
