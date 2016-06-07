module mahjong.domain.wall;

import std.random;
import std.stdio;
import std.conv;

import mahjong.domain.enums.game;
import mahjong.domain.enums.tile;
import mahjong.domain.enums.wall;
import mahjong.domain.tile;
import mahjong.engine.mahjong;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.graphics;

import dsfml.graphics;

class Wall
{
   private Tile[] tiles;
   private Texture tilesTexture;
   private int amountOfKans = 0;
   private int gameMode;

   this(const int gameMode, ref Texture tilesTexture)
   {
      this.tilesTexture = tilesTexture;
      this.gameMode = gameMode;
   }

   private void getSprites()
   {
     foreach(tile; tiles)
     {
       tile.getSprite(tilesTexture);
     }
   }

   @property public size_t length()
   {
     return tiles.length;
   }

   public void reset()
   {
      this.amountOfKans = 0;
      initialise();
      giveIDs();
      getSprites();
      shuffle();
      place();
      diceToStartPoint();
      flipFirstDoraIndicator();
   }

   public void setUp(const int gameMode)
   {
      this.gameMode = gameMode;
      reset;
   }

   private void initialise()
   {
     switch(gameMode)
     {
        case GameMode.Bamboo:
          initialiseBamboo();
          break;
        case GameMode.EightPlayer:
          initialiseEightPlayer();
          break;
        default:
          initialiseNormal();
          break;
     }
   }
   private void initialiseBamboo()
   {
     for(int j = Numbers.min; j <= Numbers.max; ++j)
     {
        for(int i = 0; i < 4; ++i)
        {
          tiles ~= new Tile(Types.bamboo, j);
          if(j == Numbers.five && i == 0)
             ++tiles[$-1].dora;
        }
     }
   }
   private void initialiseEightPlayer()
   {

   }
   private void initialiseNormal()
   { // FIXME: remove the dependence on the 'legacy' fnctions and rebuild them nicely.
     // FIXME: add dora's.
      set_up_wall(tiles);
   }
   
   private void giveIDs()
   { // FIXME: See if this can be resolved by comparing the addresses rather than an arbitrarily set value.
       size_t ID = 0;
       foreach(tile; tiles)
       {
         tile.ID = ID;
         ++ID;
       }
   }

   private void shuffle()
   in
   {
      assert(length > 0);
   }
   body
   {
      for(int i = 0; i < 500; ++i)
      {
         ulong t1 = uniform(0, length);
         ulong t2 = uniform(0, length);
         swap_tiles(tiles[t1],tiles[t2]);
      }
   }

   private void place()
   {
     switch(gameMode)
     {
        case GameMode.Bamboo:
          placeBambooWall;
          break;
        default:
          placeWall;
          break;
     }
   }

   private void placeWall()
   {
     int widthOfWall = cast(int)length / (2*amountOfPlayers.normal);
     auto size = tiles[0].getGlobalBounds;
     float undershoot = size.height/size.width;

      for(int i = 0; i < (tiles.length/2); ++i)
      {
         auto position = CENTER;
         auto movement = calculatePositionInSquare(widthOfWall, undershoot, 
                          i % widthOfWall, size);
         int wallSide = getWallSide(i, widthOfWall);
         moveToPlayer(position, movement, wallSide );
         placeBottomTile(tiles[$-1 - (2*i+1)],position);
         placeTopTile(tiles[$-1 - (2*i)],position);
         tiles[$-1 - 2*i].rotateToPlayer(wallSide);
         tiles[$-1 - (2*i+1)].rotateToPlayer(wallSide);
         // TODO: Let the draw functions draw the correct tiles first.
      }
   }
   private int getWallSide(int i, int widthOfWall)
   {
     return i / widthOfWall;
   }
   
   private void placeBambooWall()
   {
      /*
          We want the wall to be placed in the middle. The wall should be taken from the left side. Therefore, start placing them at the right hand side.
          After distributing the tiles to the players, only 10 tiles are left. Center them.
      */
      auto size = tiles[0].getGlobalBounds;
      auto position = getOutermostBambooPosition;
      for(int i = 0; i < (tiles.length/2); ++i)
      {
         placeBottomTile(tiles[$-1 - 2*i],position);
         placeTopTile(tiles[$-2 - 2*i],position);
         position.x -= size.width; 
      }
   }
   private Vector2f getOutermostBambooPosition()
   { // There are only 10 tiles left. Stack them two high. Return the position of the last tile.
      auto position = CENTER;
      auto size = tiles[0].getGlobalBounds;
      position.x += 1.5 * size.width; // Move the tile 1.5 tiles to the right.
      position.y -= 0.5 * size.height;// Move the tile 0.5 tiles to the top.
      return position;
   }
   private void placeBottomTile(ref Tile tile, const ref Vector2f position)
   {
      modifyTilePosition(tile, position, '+');
   }
   private void placeTopTile(ref Tile tile, const ref Vector2f position)
   {
      modifyTilePosition(tile, position, '-');
   }
   private void modifyTilePosition(ref Tile tile, const ref Vector2f position, char sign)
   {
      Vector2f pos = position;
      switch(sign)
      {
          case '+':
             pos.y += wallMargin;
             break;
          case '-':
             pos.y -= wallMargin;
             break;
          default:
             assert(false);
      }
      tile.setPosition(pos);
   }

   private void diceToStartPoint()
   {
      switch(gameMode)
      {
         case GameMode.Bamboo:
            break;
         default:
            diceNormally;
            break;
      }
   }
   private void diceNormally()
   {
      int result = rollDice(2);
      // Calculate which player is pointed to, and shift the split by a quarter of the wall times the player appointed.
       int split = calculateWallShift(result);
      // Start counting from the right and shift the wall back by two times (height of the wall) te result of the dice roll.
      split += 2 * result;
      splitWall(split);
   }
   private int rollDice(int amountOfDice)
   {
      int result = 0;
      for(int i = 0; i < amountOfDice; ++i)
      {
         result += uniform(0,6)+1;
      }
      return result;
   }
   private int calculateWallShift(int diceRoll)
   {
      alias plyrs = amountOfPlayers.normal;
      int wallSide = (diceRoll-1)%plyrs;
      return ((plyrs - wallSide-1) % plyrs) * to!int(length)/plyrs;
   }
   private void splitWall(const int shift)
   {
      int _shift = (shift+to!int(length)) % cast(int)length;
      auto twall = this.tiles[_shift .. $] ~ this.tiles[0 .. _shift];
      this.tiles = twall;
   }

   private void flipFirstDoraIndicator()
   {
      switch(gameMode)
      {
         case GameMode.Bamboo:
            break;
         default:
            tiles[$-5].open;
      }
   }

/*
   In-game functions.
*/
   public Tile drawTile()
   { // Not to be confused with the graphical draw functions.
      Tile drawnTile = tiles[0];
      tiles = tiles[1 .. $];
      return drawnTile;
   }
   public Tile drawKanTile()
   { // Not to be confused with the graphical draw functions nor the normal draw. In addition, this function also flips the dora indictor.
      flipDoraIndicator;
      return getKanTile;      
   }
   private void flipDoraIndicator()
   {
      // TODO: Implement flipping dora indicators!
   }
   private Tile getKanTile()
   {
      switch(gameMode)
      {
        case GameMode.Bamboo:
           return getBambooKanTile();
        default:
           return getNormalKanTile();
      }
   }
   private Tile getBambooKanTile()
   {
     return drawTile();
   }
   private Tile getNormalKanTile()
   {
      Tile kanTile = tiles[$-1];
      tiles = tiles[0 .. $-1];
      return kanTile;
   }

   public bool isExhaustiveDraw()
   {
      switch(gameMode)
      {
         case GameMode.Bamboo:
            return tiles.length <= bambooDeadWall;
         default:
            return tiles.length <= deadWallLength;
      }
   }

   public bool isAbortiveDraw()
   { // FIXME: Take into account that this is invalid in the ultrarare case in which all of the kans belong to a single player.
      return amountOfKans == 4;
   }

   public bool canStillKan()
   {
      switch(gameMode)
      {
         case GameMode.Bamboo:
            return tiles.length > 0;
         default:
            return tiles.length > deadWallLength + kanBuffer && amountOfKans < 4;
      }
   }

   public void draw(ref RenderWindow window)
   { // Not to be confused with the getters drawTile and drawKanTile
      foreach(tile; tiles)
      {
        if(!tile.isOpen)
           tile.draw(window);
      }
      foreach(tile; tiles)
      {
        if(tile.isOpen)
           tile.draw(window);
      }
   }

}
















