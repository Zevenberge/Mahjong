module mahjong.domain.player;

import std.stdio;
import std.string;
import std.random;
import std.conv;

import mahjong.domain.enums.game;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.ai;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;
import mahjong.graphics.cache.font;
import mahjong.graphics.enums.game;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.kanji;
import mahjong.graphics.enums.resources;
import mahjong.graphics.graphics;

import dsfml.graphics;


class Player
{ // General variables.
  dchar[] name = "Cal"d.dup;
  Texture iconTexture;
  Sprite icon;
  Sprite pointsBg;
  Text pointsDisplay;
  Text windsDisplay;
  string avatar = defaultTexture;
  
  int playLoc = -10;
  int points = 30000; 

  Ingame game; // Resets after every round.

  this()
  {

  }
  this(Texture iconTexture, Sprite icon)
  {
    this.iconTexture = iconTexture;
    this.icon        = icon;
  }
  this(dchar[] name, Texture iconTexture, Sprite icon)
  {
    this.name        = name;
    this.iconTexture = iconTexture;
    this.icon        = icon;
  }
  this(dchar[] name, Texture iconTexture, Sprite icon, string avatar)
  {
    this.name        = name;
    this.iconTexture = iconTexture;
    this.icon        = icon;
    this.avatar      = avatar;
  }

  public void nextRound(bool passWinds, const int amountOfPlayers)
  {
    int wind = (game.getWind + passWinds ? 1 : 0) % amountOfPlayers;
    firstGame(wind);
  }

  public void firstGame(int initialWind)
  {
     game = new Ingame(initialWind);
     placeWindsDisplay();
  }

  @property int getWind()
  {
    return game.getWind();
  }

  public void drawTile(ref Wall wall)
  {
     this.game.drawTile(wall);
  }

  public Tile getLastDiscard()
  {
     return game.getLastDiscard;
  }
  public Tile getLastTile()
  {
     return game.getLastTile;
  }

  /*
    Functions regarding drawing.
  */

  void drawWindow(ref RenderWindow window)
  {
    with(window)
    {
      draw(icon);
      draw(pointsBg);
      draw(pointsDisplay);
      draw(windsDisplay);
    }
    drawTiles(window);
  }

  private void drawTiles(ref RenderWindow window)
  {
    game.draw(window, playLoc);
  }

  /*
     Functions with regard to placing tiles and displays.
  */

  public void discard(T) (T disc)
  {
     game.discard(disc);
     placeDiscard;
  }

  Vector2i getDiscardIndex()
  {
    size_t amountOfDiscards = game.discards.length;
    int x = 0, y = 0;
    if(amountOfDiscards > (discardLines-1)*discardsPerLine)
    {
       y = discardLines-1;
       x = to!int(amountOfDiscards - (discardLines-1)*discardsPerLine - 1);
    }
    else
    {
      x = (amountOfDiscards-1) % discardsPerLine;
      y = to!int((amountOfDiscards-1) / discardsPerLine); // Should implicitely be floor()
    }
    return Vector2i(x,y);
  }

  private void placeDiscard()
  {
    if(game.discards.length > 0)
    { /*
        The discards embed a square in the center of the board. To reduce the area of the square, present an undershoot. The undershoot represents the amount of tiles that are placed to the left of the square (as seen from the player). First, we calculate the center. We then calculate the corner of the encapsulated square by trigeonometric functions. We then displace this corner to the beginning of the discard pile. Based on a few defined constants, we then calculate the topleft corner of the tile.
      */
      auto tile = getLastDiscard;
      tile.setRotation(0);
      auto tileSize = tile.getGlobalBounds;
      auto tileIndex = getDiscardIndex();
      auto movement = calculatePositionInSquare(
               discardsPerLine, discardUndershoot, tileIndex.x, tileSize);
      movement.y += tileIndex.y * tileSize.height;
      auto position = CENTER;
      moveToPlayer(position, movement, playLoc);
      tile.setPosition(position);
      tile.rotateToPlayer(playLoc); // Rotation of the tile.    
    } 
  }

  void placeRiichi()
  {

  }

  void updatePoints()
  {
    pointsDisplay.setString(to!dstring(points));
    if(points < criticalPoints)
    {
      pointsDisplay.setColor(Color.Red);
    }
    else
    {
      pointsDisplay.setColor(Color.Black);
    }
    placePointsDisplay;
  }

  void placePointsDisplay()
  {
    FloatRect bgSize = pointsBg.getGlobalBounds();
    CenterText(pointsDisplay, "both", bgSize.left, bgSize.top, bgSize.width, bgSize.height);
    pointsDisplay.move(Vector2f(0,-4));
  }

  void loadPointsDisplay()
  {
    pointsDisplay = new Text;
    pointsDisplay.setFont(pointsFont);
    pointsDisplay.setCharacterSize(16);
    pointsDisplay.setColor(Color.Black);
  }

  void placeWindsDisplay()
  {
    windsDisplay.setString(to!dstring(cast(Kanji)game.location));
    FloatRect bgSize = icon.getGlobalBounds();
    alignTopLeft(windsDisplay, bgSize);
  }

  void loadWindsDisplay()
  {
    windsDisplay = new Text;
    windsDisplay.setFont(kanjiFont);
    windsDisplay.setCharacterSize(40);
    windsDisplay.setColor(Color.Black);
  }

  void placePointsBg()
  {
    pix2scale(pointsBg,iconSize);
    pointsBg.scale = Vector2f(pointsBg.scale.x, 2* pointsBg.scale.y);
    alignBottom(pointsBg,icon.getGlobalBounds());
  }

  void loadPointsBg(ref Texture stickTexture)
  {
    pointsBg = new Sprite;
    pointsBg.setTexture(stickTexture);    
  }

   void placeIcon()
   {
     switch(playLoc)
     {
       case playerLocation.bottom:
         float xpos = width - (iconSize + iconSpacing);
         float ypos = height - iconSize;
         icon.position = Vector2f(xpos,ypos);
         break;
       case playerLocation.right:
         float xpos = width - iconSize;
         float ypos = iconSpacing;
         icon.position = Vector2f(xpos,ypos);
         break;
       case playerLocation.top:
         float xpos = iconSpacing;
         float ypos = 0;
         icon.position = Vector2f(xpos,ypos);
         break;
       case playerLocation.left:
         float xpos = 0;
         float ypos = height - (iconSize + iconSpacing);
         icon.position = Vector2f(xpos,ypos);
         break;
       default:
         CenterSprite(icon,"both");
     }
   }

   void loadIcon(string filename = defaultTexture)
   {
      iconTexture = new Texture;
      icon = new Sprite;
      load(iconTexture, icon, filename);
      pix2scale(icon, iconSize, iconSize);
   }


   Player dup()
   {
     return new Player(name, iconTexture, icon, avatar);
   }

   override string toString() const
   {
     return(format("%s-san",name));
   }

/*
   Game finisher.
*/

   bool isMahjong()
   {
      return game.isMahjong();
   }

   bool isTenpai()
   {
      return game.checkTenpai;
   }

   bool isNagashiMangan()
   {
      return game.isNagashiMangan;
   }

/*
   Functions with regard to claiming tiles.
*/

  bool isPonnable(const ref Tile discard)
  {
     return game.isPonnable(discard);
  }
  bool isRonnable(ref Tile discard)
  { // FIXME: Try to make the chain of inputs const.
     return game.isRonnable(discard);
  }

/*
  All of the functions that compose a pon.
*/

  void composePon(Tile ponnable, int amountOfTiles = 3)
  { // Take out all of the required identical tiles.
    int nthOpenPon = getNthOpenPon;
    for(int i = 0; i<amountOfTiles-1; ++i)
    {
      foreach(tile; game.closedHand.tiles)
      {
        if(is_equal(tile,ponnable))
        { 
          take_out_tile(game.closedHand.tiles, game.openHand.tiles[][nthOpenPon], tile);
          break;
        }
      }
    } 
  }

  private int getNthOpenPon()
  {  // Returns the amount of open pons.
     for(int n=0; n < amountOfSets; ++n)
     {
       if(game.openHand.tiles[][n] is null)
       {
         return n;
       }
     }
     assert(false);
  }

  void placeDibsedTile(const ref int amountOfOpenSets, const int AmountOfPlayers = amountOfPlayers.normal) // Place the pon or chi
  in                                // amountOfOpenSets is excluding the one to be placed.
  {
    assert(amountOfOpenSets < amountOfSets);
    assert(amountOfOpenSets >= 0);
    if(!(game.openHand.tiles[][amountOfOpenSets] is null))
    {
      throw new Exception("Placing null tiles!");
    }
  }
  body
  {
    alias i = amountOfOpenSets;
    auto pon = game.openHand.tiles[][i];
    sort_hand(pon);
    FloatRect rightBounds;
    if(i > 0)
    {
      rightBounds = game.openHand.getGlobalBounds(i-1);
    }
    else
    {
      rightBounds = icon.getGlobalBounds;
      rightBounds.left -= openMargin.avatar;
    }
    placeTiles(pon, rightBounds.left, AmountOfPlayers);
    game.openHand.tiles[][i] = pon;
  }

  void placeTiles(ref Tile[] pon, const float rightBound, const int AmountOfPlayers = amountOfPlayers.normal)
  { // Give the tiles the coordinates they need.
     float rightB = rightBound;
     float[2] center = [CENTER.x, CENTER.y];
     reorderPon(pon, AmountOfPlayers);
     foreach_reverse(tile; pon)
     {
       float[2] position;
       tile.setRotation(0);
       FloatRect tileSize = tile.getGlobalBounds();
       if((tile.origin != Origin.wall) && (tile.origin != game.location))
       { // This is the tile that should be rotated.
         tile.setRotation(90);
         position[0] = rightB;
         position[1] = openMargin.edge + tileSize.width;
       }
       else
       { // Place the tile straight up.
         position[0] = rightB - tileSize.width;
         position[1] = openMargin.edge + tileSize.height;
       }       
       rightB = tile.getGlobalBounds.left;
       float[2] movement;
       movement[] = position[] - center[];
       assert(movement[0] == position[0] - center[0]);
       assert(movement[1] == position[1] - center[1]);
       position = center;
       moveToPlayer(position, movement, playLoc);
       tile.setPosition(Vector2f(position[0], position[1]));
       tile.addRotateToPlayer(playLoc);
     }
  }

  void reorderPon(ref Tile[] pon, const int AmountOfPlayers = amountOfPlayers.normal)
  {  // Reorders the pon such that the dibsed tile refers to the person discarding it.
    int j = 0;
    foreach(tile; pon)
    {
      if((tile.origin != Origin.wall) && (tile.origin != game.location))
      { // Neither a tile from the wall nor from himself.
        if(tile.origin == ((game.location + AmountOfPlayers - 1) % AmountOfPlayers)) // If the tile is from the previous player.
        {
          swap_tiles(pon[0],pon[j]); // Place the tile first.
        }
        else if(tile.origin == ((game.location + 1) % AmountOfPlayers)) // If the tile is from the next player.
        {  
          swap_tiles(pon[$-1],pon[j]); // Place the tile last.
        }
        else
        {
            swap_tiles(pon[1],pon[j]); // Place the tile second.
        }
        break;
      }
      ++j;
    }  
  }

  /*
     Manipulate visuals.
  */

  public void showHand()
  {
    game.showHand();
  }
  public void closeHand()
  {
    game.closeHand();
  }
}


