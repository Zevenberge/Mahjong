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
   
 }
