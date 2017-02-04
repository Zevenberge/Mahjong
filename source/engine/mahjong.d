module mahjong.engine.mahjong;

import std.experimental.logger;
import std.string;
import std.range;
import std.uni;
import std.algorithm;
import std.random;
import std.process;
import std.conv; 
import std.file;

import mahjong.domain.enums.tile;
import mahjong.domain.tile;
import mahjong.engine.enums.game;
import mahjong.engine.yaku; 

void setUpWall(ref Tile[] wall, int dups = 4)
{
	for(int i = 0; i < dups; ++i)
	{
		wall ~= createSetOfTiles();
	}
	defineDoras(wall);
}

Tile[] createSetOfTiles() 
{
	dchar[] tiles = defineTiles(); // First load all mahjong tiles.
	return convertToTiles(tiles);
}

Tile[] convertToTiles(const(dchar)[] faces)
{
	Tile[] tiles;
	foreach(face; stride(faces,1))
	{
		tiles ~= getTile(face);
	}
	return tiles;
}

void defineDoras(ref Tile[] wall)
in
{
	assert(wall.length == 136, "Wall length was %s".format(wall.length));
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


dchar[] defineTiles()
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


private Tile getTile(dchar face)
{
	dchar[] tiles = defineTiles(); // Always load the default tile set such that the correct Numbers are compared!!
	Types typeOfTile;
	int value;
	int tileNumber;
	foreach(stone; stride(tiles,1))
	{
		if(stone == face)
		{
			switch (tileNumber) 
			{
				case 0: .. case 3:
					typeOfTile = Types.wind;
					value = tileNumber;
					break;
				case 4: .. case 6:
					typeOfTile = Types.dragon;
					value = tileNumber - 4;
					break;
				case 7: .. case 15:
					typeOfTile = Types.character;
					value = tileNumber - 7;
					break;
				case 16: .. case 24:
					typeOfTile = Types.bamboo;
					value = tileNumber - 16;
					break;
				case 25: .. case 33:
					typeOfTile = Types.ball;
					value = tileNumber - 25;
					break;
				default:
					fatal("Could not identify tile by the face. Terminating program.");
			}
			break;
		}
		++tileNumber;
	}
	auto tile = new Tile;
	tile.face = face;
	tile.type = typeOfTile;
	tile.value = value;
	return tile;
}
unittest{
	import std.stdio;
	writeln("Checking the labelling of the wall...");
	Tile[] wall;
	setUpWall(wall);
	foreach(stone; wall)
	{
		if (stone.face == '🀀')
		{
			assert(stone.type == Types.wind);
			assert(stone.value == Winds.east);
		} 
		else if (stone.face == '🀏')
		{  
			assert(stone.type == Types.character);
			assert(stone.value == Numbers.nine);
		}
	}
	writeln(" The tiles are correctly labelled.");
}

/*
 Shuffle the tiles in the wall. Take a slice off the middle of the wall and place it at the end.
 */
void shuffleWall(ref Tile[] wall)
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
		swapTiles(wall[t1],wall[t2]);
	}
}

deprecated bool isEqual(const Tile tileA, const Tile tileB)
{
	return (tileA.type == tileB.type) && (tileA.value == tileB.value);
}
unittest
{
	import std.stdio;
	writeln("Checking the isEqual function for tiles...");
	Tile[] wall;
	setUpWall(wall);
	int i = uniform(0, to!int(wall.length));
	assert(isEqual(wall[i], wall[i]));
	writeln(" The isEqual function is correct.");
}

deprecated bool isIdentical(const ref Tile tileA, const ref Tile tileB)
{
	if((tileA.id == tileB.id) && isEqual(tileA,tileB))
	{
		return true;
	}
	else
	{
		return false;
	}
}
/**
 Checks whether tileB follows on tileA
 */
bool isConstructive(const Tile tileA, const Tile tileB)
{
	return (tileA.type == tileB.type) 
		&& (tileA.value == tileB.value - 1);
}
///
unittest
{
	import std.stdio;
	writeln("Checking the isConstructive function...");
	auto one = new Tile;
	with(one)
	{
		value = 1;
		type = Types.bamboo;
	}
	
	auto two = new Tile;
	with(two)
	{
		value = 2;
		type = Types.bamboo;
	}
	assert(isConstructive(one, two));
	assert(!isConstructive(two, one));
	auto three = new Tile;
	with(three)
	{
		value = 3;
		type = Types.bamboo;
	}	
	assert(!isConstructive(one, three));
	auto otherTwo = new Tile;
	with(otherTwo)
	{
		value = 2;
		type = Types.ball;
	}
	assert(!.isConstructive(one, otherTwo));
	
	writeln(" The isConstructive function is correct.");
}

bool scanHand(Tile[] hand, int chis = 0, int pons = 0, int pairs = 0)
in {assert(hand.length > 0);}
out {assert(hand.length > 0);}
body
{ /*
	       See if the current hand is a legit mahjong hand.
	       */
	sortHand(hand);
	bool isMahjong=false;
	// Run a dedicated scan for the weird hands, like Thirteen Orphans and Seven pairs, but only if the hand has exactly 14 tiles.
	if(hand.length == 14) 
	{
		if(isSevenPairs(hand) || isThirteenOrphans(hand))
		{ 
			isMahjong = true;
			return isMahjong;
		}
	}
	Tile[] mahjongHand;
	/*
	 int chis = 0; // Amount of pons in the hand.
	 int pons = 0; // Amount of chis in the hand.
	 int pairs = 0; // Amount of pairs in the hand.
	 */

	//  Check the regular hands.
	isMahjong = scanMahjong(hand, mahjongHand, chis, pairs, pons);
	return isMahjong;
}

private bool isSevenPairs(const Tile[] hand)
{ 
	if(hand.length != 14) return false;
	for(int i=0; i<7; ++i)
	{
		if(hand.length > 2*i+2) 
		{ // Check if no two pairs are the same, only if the hand size allows it.
			if(isEqual(hand[2*i],hand[2*i+2]))
			{ 
				return false;
			} // Return if we have three identical tiles.
		}
		if(!isEqual(hand[2*i],hand[2*i+1]))
		{ // Check whether is is a pair.
			return false;
		}  // If it is no pair, it is no seven pairs hand.
	}
	return true;
}
private bool isThirteenOrphans(const Tile[] hand)
{ 
	if(hand.length != 14) return false;
	int pairs = 0;
	
	for(int i = 0; i < 13; ++i)
	{ 
		auto honour = new Tile;
		
		switch(i){
			case 0: .. case 3: // Winds
				honour.type = Types.wind;
				honour.value = i;
				break;
			case 4: .. case 6: // Dragons
				honour.type = Types.dragon;
				honour.value = i % (Winds.max + 1);
				break;
			case 7, 8:         // Characters
				honour.type = Types.character;
				honour.value = isOdd(i) ? Numbers.one : Numbers.nine;
				break;
			case 9, 10:        // Bamboos
				honour.type = Types.bamboo;
				honour.value = isOdd(i) ? Numbers.one : Numbers.nine;
				break;
			case 11, 12:       // Balls
				honour.type = Types.ball;
				honour.value = isOdd(i) ? Numbers.one : Numbers.nine;
				break;
			default:
				assert(false);
		}
		if(!isEqual(hand[i+pairs], honour)) //If the tile is not the honour we are looking for
		{ 
			return false;  
		}
		if((i + pairs + 1) < hand.length) 
		{
			if(isEqual(hand[i+pairs], hand[i+pairs+1])) // If we have a pair
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
private bool scanMahjong(ref Tile[] hand, ref Tile[] mahjongHand, ref int chis, ref int pairs, ref int pons)
{ /*
	   This subroutine checks whether the hand at hand is a mahjong hand. It does - most explicitely- NOT take into account yakus. The subroutine brute-forces the possible combinations. It first checks if the first two tiles form a pair (max. 1). Then it checks if the first three tiles form a pon. If it fails, it returns a false.

	   pairs --- pons  --- chis                <- finds a pair
	   +- pons  --- chis                <- finds a pon
	   +- pons  -- chis       <- finds nothing and returns to the previous layer, in which it can still find a chi.

	   */
	bool isSet = false;
	bool isMahjong = false;
	Tile[] temphand = hand.dup;
	Tile[] tempmahj = mahjongHand.dup;
	if(pairs < 1)
	{ // Check if there is a pair, but only if there is not yet a pair.
		isSet = scanEquals(temphand, tempmahj, pairs, Set.pair);
		isMahjong = scanProgression(hand, temphand, mahjongHand, tempmahj, chis, pairs, pons, isSet);
		if(isMahjong) {
			return isMahjong;
		} else {
			assert(!isMahjong); 
			if(isSet) {
				--pairs;}} // Decrease the amount of pairs by one if this is not the solution.
	}

	temphand = hand.dup;
	tempmahj = mahjongHand.dup;
	// Check if there is a pon.
	isSet = scanEquals(temphand, tempmahj, pons, Set.pon);
	isMahjong = scanProgression(hand, temphand, mahjongHand, tempmahj, chis, pairs, pons, isSet);
	if(isMahjong) {
		return isMahjong;
	} else { 
		assert(!isMahjong); 
		if(isSet) {
			--pons;}} // Decrease the amount of pons by one if this is not the solution.

	temphand = hand.dup;
	tempmahj = mahjongHand.dup;
	// Check if there is a chi.
	isSet = scanChis(temphand, tempmahj, chis);
	isMahjong = scanProgression(hand, temphand, mahjongHand, tempmahj, chis, pairs, pons, isSet);
	if(isMahjong) {
		return isMahjong;
	} else {
		assert(!isMahjong); 
		if(isSet) {
			--chis;}} // Decrease the amount of pons by one if this is not the solution.
	return isMahjong;
}
private bool scanProgression(ref Tile[] hand, ref Tile[] temphand, ref Tile[] mahjongHand, ref Tile[] tempmahj, ref int chis, ref int pairs, ref int pons, bool isSet)
{   /* 
	     Check whether the mahjong check can advance to the next stage.
	     */

	bool isMahjong = false;
	if(isSet)
	{
		int amountOfSets = chis + pons;
		if((amountOfSets == 4) && (pairs == 1))
		{ isMahjong = true;
			hand = tempmahj.dup;
			mahjongHand = tempmahj.dup;
			//writeln();
			return isMahjong;
		} else {
			isMahjong = scanMahjong(temphand, tempmahj, chis, pairs, pons);
			if(isMahjong){
				hand = temphand.dup;
				mahjongHand = tempmahj.dup;
			}
		} 
	}
	return isMahjong;
}
private bool scanChis(ref Tile[] hand, ref Tile[] final_hand, ref int chis)
{ /*
	   This subroutine checks whether there is a chi hidden in the beginning of the hand. It should also take into account that there could be doubles, i.e. 1-2-2-2-3. Subtract the chi from the initial hand.
	   */
	if(hand[0].type < Types.character)  // If the tile is a wind or a dragon, then abort the function.
	{ return false; }

	Tile[] mutehand = hand.dup; // Create a back-up of the hand that can be mutated at will.
	Tile[] mutefinal;       // Create a temporary array that collects the chi.
	mutefinal ~= mutehand[0];
	mutehand = mutehand[1 .. $]; // Subtract the tile from the hand.

	for(int i=0;(i < 5) && (i < mutehand.length);++i)
	{ 
		if(isConstructive(mutefinal[$-1], mutehand[i]))
		{
			takeOutTile(mutehand, mutefinal, i); // The second tile in a row
			for( ; (i < 10) && (i < mutehand.length); ++i)
			{
				if(isConstructive(mutefinal[$-1], mutehand[i]))
				{
					takeOutTile(mutehand, mutefinal, i); // The chi is completed.
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
/++

 +/
void takeOutTile(ref Tile[] hand, ref Tile[] output, Tile takenOut)
{
	int i = 0;
	foreach(tile; hand)
	{
		if(tile.isIdentical(takenOut))
		{
			takeOutTile(hand, output, i);
			return;
		}
		++i;
	}
	throw new Exception("Tile not found");
}
/// Ditto
void takeOutTile(ref Tile[] hand, ref Tile[] output, const size_t index, size_t count = 1)
{
	auto end = count + index; 
	Tile[] temphand;
	output ~= hand[index .. end];
	temphand ~= hand[end .. $];
	hand = hand[0 .. index];
	hand ~= temphand;
}
///
unittest 
{
	import std.stdio;
	import std.algorithm.searching;
	writeln("Checking the takeOutTile function...");
	auto tile = new Tile;
	Tile a = new Tile, b = new Tile;
	Tile[] hand;
	hand = hand ~ a ~ tile ~ b;
	Tile[] takenOut;	
	takeOutTile(hand, takenOut, 1);
	assert(takenOut.length == 1, "Only one tile should be taken out");
	assert(takenOut[0].id == tile.id, "The tile that was taken out should be the one that was determined");
	assert(hand.length == 2, "Tile should be taken out");
	assert(hand.all!(t => t.id != tile.id), "The tile should not be in the wall any more.");
}
unittest // Range overload
{
	import std.stdio;
	import std.algorithm.searching;
	writeln("Checking the takeOutTile function...");
	auto tile = new Tile;
	auto a = new Tile, b = new Tile;
	Tile[] hand;
	hand = hand ~ a ~ tile ~ b;
	Tile[] takenOut;	
	takeOutTile(hand, takenOut, 1, 2);
	assert(takenOut.length == 2, "Two tiles should be taken out");
	assert(takenOut[0].id == tile.id, "The first tile that was taken out should be the one that was determined");
	assert(hand.length == 1, "Only one sould remain.");
	assert(hand.all!(t => t.id == a.id), "The tile should not be in the wall any more.");
}

private bool scanEquals(ref Tile[] hand, ref Tile[] final_hand,  ref int pairs, const int distance)
{ /* distance = set.pair or set.pon
	   This subroutine checks if the first few tiles form a set and then subtracts them from the inititial hand.
	   */
	if(hand.length > distance)
	{ 
		if(!isEqual(hand[0],hand[distance])) 
		{return false;}
		
		final_hand ~= hand[0 .. distance+1];
		hand = hand[distance+1 .. $];
		++pairs;
		return true;
	} else { return false;}
}
unittest // Check whether the example hands are seen as mahjong hands.
{
	import std.stdio;
	import std.path;

	void testHands(string filename, const bool isHand)
	{
		writeln("Looking for ", filename.asAbsolutePath);
		auto output = readLines(filename);
		foreach(line; output)
		{   
			assert(line.length == 14, "A complete hand is 14 tiles");
			auto hand = convertToTiles(line);
			sortHand(hand);
			bool isMahjong;
			isMahjong = scanHand(hand);
			assert(isHand == isMahjong);
			write("The mahjong is ", isMahjong, ".  ");
			foreach(stone; hand) {write(stone);}
			writeln();
		}
		writeln();

	}

	writeln("Checking the example hands...");
	testHands("test/nine_gates", true);
	testHands("test/example_hands", true);
	testHands("test/unlegit_hands", false);
	writeln(" The function reads the example hands correctly.");
}

void sortHand(ref Tile[] hand)
{  /*
	    Sort the tiles in the hand. Arrange them by their type and their value.
	    */
	for( ; ; )
	{
		Tile[] hand_prev = hand.dup;
		for(int i = 1; i < hand.length; ++i)
		{  // Sort by type first (dragon, wind, character, bamboo, ball)
			if(hand[i].type < hand[i-1].type) {
				swapTiles(hand[i], hand[i-1]);
			} else if(hand[i].type == hand[i-1].type) {
				// Then sort them by value.
				if(hand[i].value < hand[i-1].value)
				{ swapTiles(hand[i], hand[i-1]);
				} else if(hand[i].value == hand[i-1].value)
				{ if(hand[i].dora > hand[i-1].dora)
					{ swapTiles(hand[i], hand[i-1]);}
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

void swapTiles(ref Tile tileA, ref Tile tileB)
{
	Tile tileC = tileA;
	tileA = tileB;
	tileB = tileC;
}
unittest
{
	auto tileA = new Tile();
	with(tileA)
	{
		face = 'p';
		value = 1;
		type = Types.wind;
	}
	auto tileB = new Tile();
	with(tileB)
	{
		face = 'c';
		value = 2;
		type = Types.character;
	}
	swapTiles(tileA,tileB);
	assert(tileA.value == 2 && tileA.type == Types.character, "A not swapped");
	assert(tileB.value == 1 && tileB.type == Types.wind, "B not swapped");

}
version(unittest)
{
	import std.stdio;
	/// Read the given file into dstring lines
	dstring[] readLines(string filename)
	{ 
		if(exists(filename))
		{ 
			dstring[] output;
			auto file = File(filename,"r");
			while(!file.eof())
			{
				string line = chomp(file.readln());
				dchar[] dline;
				foreach(face; stride(line,1))
				{
					dline ~= face;
				}
				output ~= dline.to!dstring;
			}
			return output;
		} 
		else 
		{
			throw new Exception("The file does not exist.");
		}
	}
}

void printTiles(Tile[] wall)
{
	for(int i=0; i<5; ++i)
	{
		switch (cast(Types)wall[i].type){
			case Types.dragon:
				trace(wall[i].face, " is a ", cast(Types)wall[i].type, " with value ", cast(Dragons)wall[i].value, ".");
				break;
			case Types.wind:
				trace(wall[i].face, " is a ", cast(Types)wall[i].type, " with value ", cast(Winds)wall[i].value, ".");
				break;
			default:
				trace(wall[i].face, " is a ", cast(Types)wall[i].type, " with value ", wall[i].value+1, ".");
		}
	}
}

bool isOdd(const int i)
in
{ 
	assert(i >= 0); 
}
body
{ 
	return i % 2 == 1;
}
unittest{
	assert(isOdd(9));
	assert(!isOdd(8));
}

bool isIn(const Tile wanted, const Tile[] deck)
{
	foreach(tile; deck)
		if(isEqual(tile, wanted))
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
		if(isEqual(tile, wanted))
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
		if(isEqual(tile, wanted) && !isIdentical(tile, wanted))
		{
			return true;
		}
	}
	return false;
}

bool isConnected(const ref Tile[] hand, const ref Tile tile)
{
	auto connection = new Tile;
	connection.type = tile.type;

	if(!tile.isHonour)
	{ // See whether a tile within range 2 of the same suit is in the hand.
		for(connection.value = tile.value-2; connection.value <= tile.value+2; ++connection.value)
		{
			if(connection.value == tile.value)
			{ // Skip the original value, as it requires an extra step.
				++connection.value;
			}
			if(isIn(hand, connection))
			{
				return true;
			}
		} 
	}
	return isAnotherIn(hand, tile);
}

void message(const dchar[] mail)
{ // Write a message to the desired output.
	info(mail);
}
