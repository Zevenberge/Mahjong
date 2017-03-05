module mahjong.engine.mahjong;

import std.experimental.logger;
import std.algorithm;
import std.array;
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
import mahjong.share.range;
import mahjong.share.numbers;

struct MahjongResult
{
	const bool isMahjong;
	const Set[] sets;
}

abstract class Set
{
	this(const Tile[] tiles) pure
	{
		this.tiles = tiles;
	}
	const Tile[] tiles;
}

class ThirteenOrphanSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}
}

class SevenPairsSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}
}

class PonSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}
}

class ChiSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}
}

class PairSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}
}

MahjongResult scanHandForMahjong(const ClosedHand closedHand, const OpenHand openHand) 
{
	return scanHandForMahjong(closedHand.tiles, openHand.amountOfPons);
}

MahjongResult scanHandForMahjong(const(Tile)[] hand, int pons = 0)
in {assert(hand.length > 0);}
out {assert(hand.length > 0);}
body
{ /*
	   See if the current hand is a legit mahjong hand.
	   */
	auto sortedHand = sortHand(hand);
	// Run a dedicated scan for the weird hands, like Thirteen Orphans and Seven pairs, 
	// but only if the hand has exactly 14 tiles.
	if(hand.length == 14) 
	{
		if(isSevenPairs(sortedHand))
		{
			return MahjongResult(true, [new SevenPairsSet(sortedHand)]);
		}
		if(isThirteenOrphans(hand))
		{ 
			return MahjongResult(true, [new ThirteenOrphanSet(sortedHand)]);
		}
	}

	auto progress = scanRegularMahjong(new Progress(sortedHand, pons));
	Set[] sets;
	sets ~= progress.pons;
	sets ~= progress.chis;
	sets ~= progress.pairs;
	return MahjongResult(progress.isMahjong, sets);
}

private bool isSevenPairs(const Tile[] hand) pure
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
private bool isThirteenOrphans(const Tile[] hand) pure
{
	struct ComparativeTile
	{
		int type;
		int value;

		bool hasEqualValue(const Tile other) pure const
		{
			return other.type == type && other.value == value;
		}
	}
	if(hand.length != 14) return false;
	int pairs = 0;
	
	for(int i = 0; i < 13; ++i)
	{ 
		ComparativeTile honour;

		switch(i){
			case 0: .. case 3: // Winds
				honour = ComparativeTile(Types.wind, i);
				break;
			case 4: .. case 6: // Dragons
				honour = ComparativeTile(Types.dragon, i % (Winds.max + 1));
				break;
			case 7, 8:         // Characters
				honour = ComparativeTile(Types.character, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			case 9, 10:        // Bamboos
				honour = ComparativeTile(Types.bamboo, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			case 11, 12:       // Balls
				honour = ComparativeTile(Types.ball, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			default:
				assert(false);
		}
		if(!honour.hasEqualValue(hand[i+pairs])) //If the tile is not the honour we are looking for
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

private class Progress
{
	this(const(Tile)[] hand, size_t initialSets) pure
	{
		this.hand = hand;
		_initialSets = initialSets;
	}

	private const size_t _initialSets;
	const(Tile)[] hand;
	PairSet[] pairs;
	PonSet[] pons;
	ChiSet[] chis;

	void convertToPair(const HandSetSeperation handSetSeperation) pure
	{
		if(!handSetSeperation.isSeperated) return;
		hand = handSetSeperation.hand;
		pairs ~= new PairSet(handSetSeperation.set);
	}

	void convertToPon(const HandSetSeperation handSetSeperation) pure
	{
		if(!handSetSeperation.isSeperated) return;
		hand = handSetSeperation.hand;
		pons ~= new PonSet(handSetSeperation.set);
	}

	void convertToChi(const HandSetSeperation handSetSeperation) pure
	{
		if(!handSetSeperation.isSeperated) return;
		hand = handSetSeperation.hand;
		chis ~= new ChiSet(handSetSeperation.set);
	}

	void subtractPair() pure
	{
		auto pair = pairs[$-1];
		recoverTiles(pair.tiles);
		pairs = pairs[0 .. $-1];
	}

	void subtractPon() pure
	{
		auto pon = pons[$-1];
		recoverTiles(pon.tiles);
		pons = pons[0 .. $-1];
	}

	void subtractChi() pure
	{
		auto chi = chis[$-1];
		recoverTiles(chi.tiles);
		chis = chis[0 .. $-1];
	}

	private void recoverTiles(const(Tile)[] tiles) pure
	{
		hand = sortHand(hand ~ tiles);
	}

	private bool _isMahjong;
	bool isMahjong() @property pure const
	{
		return _isMahjong || (pairs.length == 1 &&
			pons.length + chis.length + _initialSets == 4);
	}
}

private struct HandSetSeperation
{
	const (Tile)[] hand;
	const (Tile)[] set;
	bool isSeperated() @property pure const
	{
		return set.length > 0;
	}
}

private Progress scanRegularMahjong(Progress progress) 
{ 
	/*
	   This subroutine checks whether the hand at hand is a mahjong hand. 
	   It does - most explicitely- NOT take into account yakus. 
	   The subroutine brute-forces the possible combinations. 
	   It first checks if the first two tiles form a pair (max. 1). 
	   Then it checks if the first three tiles form a pon. If it fails, it returns a false.

	   pairs --- pons  --- chis                <- finds a pair
	   +- pons  --- chis                <- finds a pon
	   +- pons  -- chis       <- finds nothing and returns to the previous layer, in which it can still find a chi.

	*/
	if(progress.pairs.length < 1)
	{ // Check if there is a pair, but only if there is not yet a pair.
		progress = attemptToResolvePair(progress);
		if(progress.isMahjong) return progress;
	}
	progress = attemptToResolvePon(progress);
	if(progress.isMahjong) return progress;
	return attemptToResolveChi(progress);
}

private Progress attemptToResolvePair(Progress progress) 
{
	if(progress.hand.length < 2) return progress;
	auto pairSeperation = seperateEqualSetOfGivenLength(progress.hand, 2);
	progress.convertToPair(pairSeperation);
	if(!pairSeperation.isSeperated) return progress;
	progress = scanRegularMahjong(progress);
	if(!progress.isMahjong) 
	{
		progress.subtractPair;
	}
	return progress;
}

private Progress attemptToResolvePon(Progress progress) 
{
	if(progress.hand.length < 3) return progress;
	auto ponSeperation = seperateEqualSetOfGivenLength(progress.hand, 3);
	progress.convertToPon(ponSeperation);
	if(!ponSeperation.isSeperated) return progress;
	progress = scanRegularMahjong(progress);
	if(!progress.isMahjong) 
	{
		progress.subtractPon;
	}
	return progress;
}

private Progress attemptToResolveChi(Progress progress) 
{
	if(progress.hand.length < 3) return progress;
	if(progress.hand[0].isHonour)
	{
		// Honours cannot be resolved in a chi.
		return progress;
	}
	auto chiSeperation = seperateChi(progress.hand);
	if(!chiSeperation.isSeperated) return progress;
	progress.convertToChi(chiSeperation);
	progress = scanRegularMahjong(progress);
	if(!progress.isMahjong)
	{
		progress.subtractChi;
	}
	return progress;
}

private HandSetSeperation seperateChi(const(Tile)[] hand)
{ 
	/*
	   This subroutine checks whether there is a chi hidden in the beginning of the hand. 
	   It should also take into account that there could be doubles, 
	   i.e. 1-2-2-2-3. Subtract the chi from the initial hand.
	*/

	const(Tile)[] chi;       // Create a temporary array that collects the chi.
	chi ~= hand[0];
	foreach(tile; hand.filter!(t => t.type == chi[0].type))
	{
		if(tile.value == chi[$-1].value + 1)
		{
			chi ~= tile;
			if(chi.length == 3) 
			{
				return HandSetSeperation(hand.without!((a,b) => a.id == b.id)(chi), chi);
			}
		}
	}
	return HandSetSeperation(hand);
}

private HandSetSeperation seperateEqualSetOfGivenLength(const(Tile)[] hand, const int distance) pure 
{ 
	/* distance = set.pair or set.pon
	   This subroutine checks if the first few tiles form a set and then subtracts them from the inititial hand.
	*/
	if(hand.length < distance) return HandSetSeperation(hand, null);
	auto tile = hand[0];
	auto equalTiles = hand.filter!(t => t.hasEqualValue(tile)).array;
	if(equalTiles.length < distance) return HandSetSeperation(hand, null);
	auto set = equalTiles[0 .. distance];
	return HandSetSeperation(
		hand.without!((a,b) => a.id == b.id)(set), 
		set);
}

unittest // Check whether the example hands are seen as mahjong hands.
{
	import std.stdio;
	import std.path;
	import std.string;

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
			isMahjong = scanHandForMahjong(hand).isMahjong;
			assert(isHand == isMahjong, "For %s, the mahjong should be %s".format(line, isHand));
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

