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
   /+public FloatRect getGlobalBounds()
   {
     return sprite.getGlobalBounds;
   }

   public float getRotation()
   {
      return sprite.rotation;
   }
   public void setRotation(float rotation)
   {
      sprite.rotation = rotation;
      backSprite.rotation = rotation;
   }
   public void rotateToPlayer(const int playLoc)
   {
      .rotateToPlayer(this.sprite, playLoc);
      .rotateToPlayer(this.backSprite, playLoc);
   }
   public void addRotateToPlayer(const int playLoc)
   {
      .addRotateToPlayer(this.sprite, playLoc);
      .addRotateToPlayer(this.backSprite, playLoc);
   }

   public Vector2f getPosition()
   {
      return sprite.position;
   }
   public void setPosition(Vector2f position)
   {
      sprite.position = position;
      backSprite.position = position;
   }
  
   public void getSprite(ref Texture tiles)
   { 
     getFrontSprite(tiles);
     getBackSprite(tiles);
   }
   private void getFrontSprite(ref Texture tiles)
   {
     sprite = new Sprite(tiles);
     auto bounds = getSpriteBounds;
     sprite.textureRect = bounds;
     pix2scale(sprite, tile.displayWidth);
   }
   private IntRect getSpriteBounds()
   {
		IntRect bounds;
		bounds.width = tile.width;
		bounds.height = tile.height;
		if(type < Types.character) // We have an honour.
		{
			bounds.top = tile.y0;
			if(type == Types.season)
			{
				 bounds.left = tile.x0 + (value - Seasons.min) * tile.dx;
			}
			if(type == Types.wind)
			{
				 bounds.left = tile.x0 + (value - Winds.min + (Seasons.max - Seasons.min + 1)) * tile.dx;
			}
			if(type == Types.dragon)
			{
				 bounds.left = tile.x0 + (value - Dragons.min + (Seasons.max - Seasons.min + 1 + Winds.max - Winds.min + 1)) * tile.dx;
			}
		}
		else // We have a series.
		{
			bounds.top  = tile.y0 + (type - Types.character + 1) * tile.dy;
			bounds.left = tile.x0 + (value - Numbers.min + 1) * tile.dx;
		}
		return bounds; 
   }
   private void getBackSprite(ref Texture tiles)
   { // FIXME
     backSprite = new Sprite(tiles);
     backSprite.color = Color.Red;
     auto bounds = getBackSpriteBounds;
     backSprite.textureRect = bounds;
     pix2scale(backSprite, tile.displayWidth);
   }
   private IntRect getBackSpriteBounds()
   { // TODO: make fancier.
     IntRect bounds;
     bounds.left = 0;
     bounds.top = 100;
     bounds.width = tile.width;
     bounds.height = tile.height; 
     return bounds;
   }

   public void draw(ref RenderWindow window)
   {
     if(isOpen)
     {
       drawOpen(window);
     }
     else
     {
       drawClosed(window);
     }
   }
   private void drawOpen(ref RenderWindow window)
   {
     window.draw(this.sprite);
   }
   private void drawClosed(ref RenderWindow window)
   {
     window.draw(this.backSprite);
   }+/
   
   
 }
