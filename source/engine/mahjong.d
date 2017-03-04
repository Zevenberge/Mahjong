module mahjong.engine.mahjong;

import std.experimental.logger;
import std.algorithm;
import std.random;
import std.process;
import std.conv; 
import std.file;
import std.string;

import mahjong.domain.closedhand;
import mahjong.domain.enums.tile;
import mahjong.domain.openhand;
import mahjong.domain.tile;
import mahjong.engine.enums.game;
import mahjong.engine.sort;
import mahjong.engine.yaku; 
import mahjong.share.numbers;

bool scanHandForMahjong(ClosedHand closedHand, OpenHand openHand)
{
	return scanHandForMahjong(closedHand.tiles, 0, 0, 0);
}

bool scanHandForMahjong(Tile[] hand, int chis = 0, int pons = 0, int pairs = 0)
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
			if(hand[2*i].hasEqualValue(hand[2*i+2]))
			{ 
				return false;
			} // Return if we have three identical tiles.
		}
		if(!hand[2*i].hasEqualValue(hand[2*i+1]))
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
		Tile honour;

		switch(i){
			case 0: .. case 3: // Winds
				honour = new Tile(Types.wind, i);
				break;
			case 4: .. case 6: // Dragons
				honour = new Tile(Types.dragon, i % (Winds.max + 1));
				break;
			case 7, 8:         // Characters
				honour = new Tile(Types.character, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			case 9, 10:        // Bamboos
				honour = new Tile(Types.bamboo, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			case 11, 12:       // Balls
				honour = new Tile(Types.ball, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			default:
				assert(false);
		}
		if(!hand[i+pairs].hasEqualValue(honour)) //If the tile is not the honour we are looking for
		{ 
			return false;  
		}
		if((i + pairs + 1) < hand.length) 
		{
			if(hand[i+pairs].hasEqualValue(hand[i+pairs+1])) // If we have a pair
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

	return pairs == 1;
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
		if(mutefinal[$-1].isConstructive(mutehand[i]))
		{
			takeOutTile(mutehand, mutefinal, i); // The second tile in a row
			for( ; (i < 10) && (i < mutehand.length); ++i)
			{
				if(mutefinal[$-1].isConstructive(mutehand[i]))
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

private bool scanEquals(ref Tile[] hand, ref Tile[] final_hand,  ref int pairs, const int distance)
{ /* distance = set.pair or set.pon
	   This subroutine checks if the first few tiles form a set and then subtracts them from the inititial hand.
	   */
	if(hand.length > distance)
	{ 
		if(!hand[0].hasEqualValue(hand[distance])) 
		{
			return false;
		}
		
		final_hand ~= hand[0 .. distance+1];
		hand = hand[distance+1 .. $];
		++pairs;
		return true;
	}
	return false;
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
			isMahjong = scanHandForMahjong(hand);
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


version(unittest)
{
	import std.range;
	import std.stdio;
	import mahjong.engine.creation;
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

