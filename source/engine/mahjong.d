module mahjong.engine.mahjong;

import std.experimental.logger;
import std.algorithm;
import std.array;
import std.random;
import std.conv; 
import std.file;
import std.string;

import mahjong.domain.closedhand;
import mahjong.domain.enums;
import mahjong.domain.openhand;
import mahjong.domain.ingame;
import mahjong.domain.tile;
import mahjong.engine.sort;
import mahjong.engine.yaku; 
import mahjong.share.range;
import mahjong.share.numbers;

struct MahjongResult
{
	const bool isMahjong;
	const Set[] sets;
	size_t calculateMiniPoints(const PlayerWinds ownWind, const PlayerWinds leadingWind) pure const
	{
		return sets.sum!(s => s.miniPoints(ownWind, leadingWind));
	}
	auto tiles() @property pure const
	{
		return sets.flatMap!(s => s.tiles);
	}
	bool isSevenPairs() @property pure const
	{
		return sets.length == 1 && cast(SevenPairsSet)sets[0];
	}
}

abstract class Set
{
	this(const Tile[] tiles) pure
	{
		this.tiles = tiles;
	}
	const Tile[] tiles;
	abstract size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const;
	bool isOpen() @property pure const
	{
		return tiles.any!(t => t.origin !is null);
	}
}

class ThirteenOrphanSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}

	override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
	{
		return 0;
	}
}

unittest
{
	auto set = new ThirteenOrphanSet(null);
	assert(set.miniPoints(PlayerWinds.east, PlayerWinds.north) == 0, "A thirteen orphan set should have no minipoints whatshowever");
}

class SevenPairsSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}

	override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
	{
		return 0;
	}
}

unittest
{
	auto set = new SevenPairsSet(null);
	assert(set.miniPoints(PlayerWinds.west, PlayerWinds.east) == 0, "A seven pairs set should have no minipoints whatshowever");
}

class PonSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}

	override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
	{
		size_t points = 4;
		if(isOpen) points /= 2;
		if(isKan) points *= 4;
		if(isSetOfHonoursOrTerminals) points *= 2;
		return points;
	}

	private bool isKan() pure const
	{
		return tiles.length == 4;
	}

	private bool isSetOfHonoursOrTerminals() pure const
	{
		return tiles[0].isHonour || tiles[0].isTerminal;
	}
}

unittest
{
	import mahjong.engine.creation;
	auto normalPon = "🀝🀝🀝"d.convertToTiles;
	auto ponSet = new PonSet(normalPon);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 4, "A closed normal is 4 points");
	normalPon[0].origin = new Ingame(PlayerWinds.east);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 2, "An open normal pon is 2");
}

unittest
{
	import mahjong.engine.creation;
	auto terminalPon = "🀡🀡🀡"d.convertToTiles;
	auto ponSet = new PonSet(terminalPon);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 8, "A closed terminal is 8 points");
	terminalPon[0].origin = new Ingame(PlayerWinds.east);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 4, "An open terminal pon is 4");
}

unittest
{
	import mahjong.engine.creation;
	auto honourPon = "🀃🀃🀃"d.convertToTiles;
	auto ponSet = new PonSet(honourPon);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 8, "A closed honour is 8 points");
	honourPon[0].origin = new Ingame(PlayerWinds.east);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 4, "An open honour pon is 4");
}

unittest
{
	import mahjong.engine.creation;
	auto normalKan = "🀝🀝🀝🀝"d.convertToTiles;
	auto ponSet = new PonSet(normalKan);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 16, "A closed normal kan is 16 points");
	normalKan[0].origin = new Ingame(PlayerWinds.east);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 8, "An open normal kan is 8");
}

unittest
{
	import mahjong.engine.creation;
	auto terminalKan = "🀡🀡🀡🀡"d.convertToTiles;
	auto ponSet = new PonSet(terminalKan);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 32, "A closed terminal is 32 points");
	terminalKan[0].origin = new Ingame(PlayerWinds.east);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 16, "An open terminal pon is 16");
}

unittest
{
	import mahjong.engine.creation;
	auto honourKan = "🀃🀃🀃🀃"d.convertToTiles;
	auto ponSet = new PonSet(honourKan);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 32, "A closed honour is 32 points");
	honourKan[0].origin = new Ingame(PlayerWinds.east);
	assert(ponSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 16, "An open honour pon is 16");
}
class ChiSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}

	override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
	{
		return 0;
	}
}

unittest
{
	auto chiSet = new ChiSet(null);
	assert(chiSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 0, "A chi should give no minipoints whatshowever");
}

class PairSet : Set
{
	this(const Tile[] tiles) pure
	{
		super(tiles);
	}

	override size_t miniPoints(PlayerWinds ownWind, PlayerWinds leadingWind) pure const
	{
		if(tiles[0].type == Types.dragon)
		{
			return 2;
		}
		if(tiles[0].type == Types.wind)
		{
			return tiles[0].value == ownWind || tiles[0].value == leadingWind
				? 2 
				: 0;
		}
		return 0;
	}
}

unittest
{
	import mahjong.engine.creation;
	auto normalPair = "🀡🀡"d.convertToTiles;
	auto pairSet = new PairSet(normalPair);
	assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 0, "A normal pair should have no minipoints");
}

unittest
{
	import mahjong.engine.creation;
	auto pairOfNorths = "🀃🀃"d.convertToTiles;
	auto pairSet = new PairSet(pairOfNorths);
	assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.south) == 0, "A pair of winds that is not leading nor own does not give minipoints");
	assert(pairSet.miniPoints(PlayerWinds.north, PlayerWinds.south) == 2, "If the wind is the own wind, it is 2 points");
	assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.north) == 2, "If the wind is the leading wind, it is 2 points");
}

unittest
{
	import mahjong.engine.creation;
	auto pairOfDragons = "🀄🀄"d.convertToTiles;
	auto pairSet = new PairSet(pairOfDragons);
	assert(pairSet.miniPoints(PlayerWinds.east, PlayerWinds.east) == 2, "A dragon pair is always 2 points");
}

MahjongResult scanHandForMahjong(const Ingame player) pure
{
	return scanHandForMahjong(player.closedHand.tiles, player.openHand.sets);
}

MahjongResult scanHandForMahjong(const Ingame player, const Tile discard) pure
{
	return scanHandForMahjong(player.closedHand.tiles ~ discard, player.openHand.sets);
}

unittest
{
	import mahjong.engine.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto openHand = new OpenHand;
	openHand.addPon("🀃🀃🀃"d.convertToTiles);
	auto ingame = new Ingame(PlayerWinds.south);
	ingame.closedHand = closedHand;
	ingame.openHand = openHand;
	assert(scanHandForMahjong(ingame).isMahjong, "An open pon should count towards mahjong");
}

unittest
{
	import mahjong.engine.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto openHand = new OpenHand;
	openHand.addChi("🀓🀔🀕"d.convertToTiles);
	auto ingame = new Ingame(PlayerWinds.east);
	ingame.closedHand = closedHand;
	ingame.openHand = openHand;
	assert(scanHandForMahjong(ingame).isMahjong, "An open chi should count towards mahjong");
}

private MahjongResult scanHandForMahjong(const(Tile)[] hand, const(Set[]) openSets) pure 
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

	auto progress = scanRegularMahjong(new Progress(sortedHand, openSets));
	const(Set)[] sets;
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
	this(const(Tile)[] hand, const(Set[]) initialSets) pure
	{
		this.hand = hand;
		foreach(set; initialSets)
		{
			auto pon = cast(const(PonSet))set;
			if(pon) pons ~= pon;
			auto chi = cast(const(ChiSet))set;
			if(chi) chis ~= chi;
		}
	}

	const(Tile)[] hand;
	const(PairSet)[] pairs;
	const(PonSet)[] pons;
	const(ChiSet)[] chis;

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
			pons.length + chis.length == 4);
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

private Progress scanRegularMahjong(Progress progress) pure
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

private Progress attemptToResolvePair(Progress progress) pure
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

private Progress attemptToResolvePon(Progress progress) pure
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

private Progress attemptToResolveChi(Progress progress) pure
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

private HandSetSeperation seperateChi(const(Tile)[] hand) pure
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
			isMahjong = scanHandForMahjong(hand, null).isMahjong;
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

