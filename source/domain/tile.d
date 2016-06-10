module mahjong.domain.tile;

import std.stdio;
import std.conv;
import std.random;
import std.string;
import std.uuid;

import mahjong.domain.enums.tile;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.engine.ai;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.graphics;

import dsfml.graphics;


class Tile
{ // FIXME: Increase encapsulation.
	dchar face; // The unicode face of the tile. TODO: remove dependacy on unicode face.
	int type;  // Winds, dragons, etc
	int value; // East - North, Green - White, one  - nine.
	UUID id;

	int dora = 0;
	int origin = Origin.wall; // Origin of the tile in in-game winds.
	private bool _isOpen = false;

    private Sprite sprite;
    private Sprite backSprite;

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
