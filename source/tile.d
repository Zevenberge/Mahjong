module tile_mod;

import std.stdio;
import std.string;
import std.random;
import std.conv;

import enumlist;
import graphics;
import mahjong;
import ai;
import meta;
import player;
import objects;

import dsfml.graphics;


class Tile
 { // FIXME: Increase encapsulation.
   dchar face; // The unicode face of the tile. TODO: remove dependacy on unicode face.
   int type;  // Winds, dragons, etc
   int value; // East - North, Green - White, one  - nine.
   size_t ID; // Unique tile ID

   int dora = 0;
   int origin = enumlist.origin.wall; // Origin of the tile in in-game winds.
   private bool _isOpen = false;

   private Sprite sprite;
   private Sprite backSprite;

   this()
   {
   }
   this(int type, int value)
   {
     this.type = type;
     this.value = value;
   } 

   public FloatRect getGlobalBounds()
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
   { // TODO: Get the back also.
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
     if(type < types.character) // We have an honour.
     {
       bounds.top = tile.y0;
       if(type == types.season)
       {
         bounds.left = tile.x0 + (value - seasons.min) * tile.dx;
       }
       if(type == types.wind)
       {
         bounds.left = tile.x0 + (value - winds.min + (seasons.max - seasons.min + 1)) * tile.dx;
       }
       if(type == types.dragon)
       {
         bounds.left = tile.x0 + (value - dragons.min + (seasons.max - seasons.min + 1 + winds.max - winds.min + 1)) * tile.dx;
       }
     }
     else // We have a series.
     {
        bounds.top  = tile.y0 + (type - types.character + 1) * tile.dy;
        bounds.left = tile.x0 + (value - characters.min + 1) * tile.dx;
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
   }

   @property public void close()
   {
     this._isOpen = false;
   }
   @property public void open()
   {
     this._isOpen = true;
   }

   @property public bool isOpen()
   {
      return this._isOpen;
   }

   override string toString() const
   {
     return(to!string(face));
   }
 }
