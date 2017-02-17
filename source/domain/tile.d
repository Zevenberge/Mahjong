module mahjong.domain.tile;

import std.conv;
import std.uuid;

import mahjong.domain.enums.tile;
import mahjong.engine.enums.game;

class Tile
{ // FIXME: Increase encapsulation.
	dchar face; // The unicode face of the tile. TODO: remove dependacy on unicode face.
	const int type;  // Winds, dragons, etc
	const int value; // East - North, Green - White, one  - nine.
	const UUID id;

	int dora = 0;
	int origin = Origin.wall; // Origin of the tile in in-game winds.
	private bool _isOpen = false;
   
    this(int type, int value)
    {
		id = randomUUID;
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
   
	bool isIdentical(const Tile other) pure const
	{
		return id == other.id;
	}

	bool hasEqualValue(const Tile other) pure const
	{
		return type == other.type && value == other.value;
	}
 }

unittest
{
	auto tile = new Tile(1, 4);
	assert(tile.isIdentical(tile), "Tile was not identical with itself");
	auto anotherTile = new Tile(1, 4);
	assert(!tile.isIdentical(anotherTile), "Tile was a different tile");
}

unittest
{
	auto tile = new Tile(Types.wind, 1);
	assert(tile.isHonour, "Tile should have been an honour");
	tile = new Tile(Types.dragon, 1);
	assert(tile.isHonour, "Tile should have been an honour");
	tile = new Tile(Types.character, 1);
	assert(!tile.isHonour, "Tile should not have been an honour");
	tile = new Tile(Types.bamboo, 1);
	assert(!tile.isHonour, "Tile should not have been an honour");
	tile = new Tile(Types.ball, 1);
	assert(!tile.isHonour, "Tile should not have been an honour");
}

unittest
{
	auto tile = new Tile(Types.character, Numbers.one);
	assert(tile.isTerminal, "Tile should have been a terminal");
	tile = new Tile(Types.character, Numbers.two);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.character, Numbers.three);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.character, Numbers.four);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.character, Numbers.five);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.character, Numbers.six);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.character, Numbers.seven);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.character, Numbers.eight);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.character, Numbers.nine);
	assert(tile.isTerminal, "Tile should have been a terminal");
	tile = new Tile(Types.wind, Winds.east);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
	tile = new Tile(Types.dragon, Dragons.green);
	assert(!tile.isTerminal, "Tile should not have been a terminal");
}

unittest
{
	auto tileA = new Tile(Types.dragon, Dragons.green);
	auto tileB = new Tile(Types.dragon, Dragons.green);
	assert(tileA.hasEqualValue(tileB), "Equal tiles were not seen as equal");
	tileB = new Tile(Types.dragon, Dragons.red);
	assert(!tileA.hasEqualValue(tileB), "Non equal tiles were equal");
	tileB = new Tile(Types.wind, Dragons.red);
	assert(!tileA.hasEqualValue(tileB), "Non equal tiles were equal");
	tileB = new Tile(Types.wind, Dragons.green);
	assert(!tileA.hasEqualValue(tileB), "Non equal tiles were equal");
}