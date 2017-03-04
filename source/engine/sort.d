module mahjong.engine.sort;

import mahjong.domain.enums.tile;
import mahjong.domain.tile;

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
	auto tile = new Tile(0, 0);
	Tile a = new Tile(0,0), b = new Tile(0,0);
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
	auto tile = new Tile(0,0);
	auto a = new Tile(0,0), b = new Tile(0,0);
	Tile[] hand;
	hand = hand ~ a ~ tile ~ b;
	Tile[] takenOut;	
	takeOutTile(hand, takenOut, 1, 2);
	assert(takenOut.length == 2, "Two tiles should be taken out");
	assert(takenOut[0].id == tile.id, "The first tile that was taken out should be the one that was determined");
	assert(hand.length == 1, "Only one sould remain.");
	assert(hand.all!(t => t.id == a.id), "The tile should not be in the wall any more.");
}