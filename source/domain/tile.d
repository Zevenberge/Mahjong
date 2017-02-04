module mahjong.domain.tile;

import std.conv;
import std.uuid;

import mahjong.domain.enums.tile;
import mahjong.engine.enums.game;

class Tile
{ // FIXME: Increase encapsulation.
	dchar face; // The unicode face of the tile. TODO: remove dependacy on unicode face.
	int type;  // Winds, dragons, etc
	int value; // East - North, Green - White, one  - nine.
	UUID id;

	int dora = 0;
	int origin = Origin.wall; // Origin of the tile in in-game winds.
	private bool _isOpen = false;

    this()
    {
		id = randomUUID;
    }
   
    this(int type, int value)
    {
   		this();
    	this.type = type;
    	this.value = value;
    } 
   
	bool isHonour() @property pure const
    {
   		return type < Types.character;
    }

	bool isTerminal() @property pure const
	{
		return !isHonour && (value == Numbers.one || value == Numbers.nine);
	}

    void close() 
    {
   		this._isOpen = false;
    }
    
    void open() 
    {
     	this._isOpen = true;
    }

    bool isOpen() @property pure const
    {
      	return this._isOpen;
    }

    override string toString() const
    {
     	return(to!string(face));
    }
   
	bool isIdentical(const Tile other) pure
	{
		return id == other.id;
	}

	bool hasEqualValue(const Tile other) pure
	{
		return type == other.type && value == other.value;
	}
 }

unittest
{
	auto tile = new Tile;
	assert(tile.isIdentical(tile), "Tile was not identical with itself");
	auto anotherTile = new Tile;
	assert(!tile.isIdentical(anotherTile), "Tile was a different tile");
}

unittest
{
	import mahjong.domain.enums.tile;
	auto tile = new Tile;
	tile.type = Types.wind;
	assert(tile.isHonour, "Tile should have been an honour");
	tile.type = Types.dragon;
	assert(tile.isHonour, "Tile should have been an honour");
	tile.type = Types.character;
	assert(!tile.isHonour, "Tile should not have been an honour");
	tile.type = Types.bamboo;
	assert(!tile.isHonour, "Tile should not have been an honour");
	tile.type = Types.ball;
	assert(!tile.isHonour, "Tile should not have been an honour");
}

unittest
{
	import mahjong.domain.enums.tile;
	auto tile = new Tile;
	tile.type = Types.character;
	tile.value = Numbers.one;
	assert(tile.isTerminal, "Tile should have been a terminal");
	tile.value = Numbers.two;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.value = Numbers.three;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.value = Numbers.four;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.value = Numbers.five;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.value = Numbers.six;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.value = Numbers.seven;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.value = Numbers.eight;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.value = Numbers.nine;
	assert(tile.isTerminal, "Tile should have been a terminal");
	tile.type = Types.wind;
	tile.value = Winds.east;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile.type = Types.dragon;
	tile.value = Dragons.green;
	assert(!tile.isTerminal, "Tile should not have been a terminal");
}