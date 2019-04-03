module mahjong.engine.sort;

import std.stdio;
import std.algorithm.iteration;
import std.algorithm.sorting;
import std.array;
import mahjong.domain.enums;
import mahjong.domain.tile;

auto sortHand(Tile[] hand) pure
{  
	return hand.sort!((a, b) => 
		a.type < b.type || 
		(a.type == b.type && a.value < b.value))
		.array;
}

unittest
{
    import std.algorithm : map;
    import fluent.asserts;
	import mahjong.engine.creation;
	enum unsortedString = "🀡🀂🀃🀄🀁🀘🀅🀀🀏🀐🀄🀙🀆🀇"d;
	Tile[] unsortedTiles = unsortedString.convertToTiles;
	unsortedTiles.sortHand;
	enum sortedString = "🀀🀁🀂🀃🀅🀄🀄🀆🀇🀏🀐🀘🀙🀡"d;
    auto sortedTiles = sortedString.convertToTiles.map!(t => t._);
    unsortedTiles.map!(t => t._).should.equal(sortedTiles);
}

auto sortHand(const(Tile)[] hand) pure
{
	return hand.map!(tile => new SortableTile(tile)).array
			.sort!((a, b) => a.type < b.type || 
				(a.type == b.type && a.value < b.value)).array
			.map!(sortable => sortable.tile)
			.array;
}

unittest
{
	import mahjong.engine.creation;
    import fluent.asserts;
	writeln("Starting the test of the sort");
	enum unsortedString = "🀡🀂🀃🀄🀁🀘🀅🀀🀏🀐🀄🀙🀆🀇"d;
	const(Tile)[] unsortedTiles = unsortedString.convertToTiles;
	enum sortedString = "🀀🀁🀂🀃🀅🀄🀄🀆🀇🀏🀐🀘🀙🀡"d;
    auto sortedTiles = sortedString.convertToTiles.map!(t => t._);
    unsortedTiles.sortHand.map!(t => t._).should.equal(sortedTiles);
}

private struct SortableTile
{
	this(const(Tile) tile) pure
	{
		this.tile = tile;
		type = tile.type;
		value = tile.value;
	}

	const(Tile) tile;
	const int type;
	const int value;
}

void swapTiles(ref Tile tileA, ref Tile tileB)
{
	Tile tileC = tileA;
	tileA = tileB;
	tileB = tileC;
}
unittest
{
	auto tileA = new Tile(Types.wind, 1);
	auto tileB = new Tile(Types.character, 2);
	swapTiles(tileA,tileB);
	assert(tileA.value == 2 && tileA.type == Types.character, "A not swapped");
	assert(tileB.value == 1 && tileB.type == Types.wind, "B not swapped");
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
	auto tile = new Tile(Types.dragon, 0);
	Tile a = new Tile(Types.dragon,0), b = new Tile(Types.dragon,0);
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
	auto tile = new Tile(Types.dragon,0);
	auto a = new Tile(Types.dragon,0), b = new Tile(Types.dragon,0);
	Tile[] hand;
	hand = hand ~ a ~ tile ~ b;
	Tile[] takenOut;	
	takeOutTile(hand, takenOut, 1, 2);
	assert(takenOut.length == 2, "Two tiles should be taken out");
	assert(takenOut[0].id == tile.id, "The first tile that was taken out should be the one that was determined");
	assert(hand.length == 1, "Only one sould remain.");
	assert(hand.all!(t => t.id == a.id), "The tile should not be in the wall any more.");
}