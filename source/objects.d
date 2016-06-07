module objects;

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
import tile_mod;
import wall;

import dsfml.graphics;


class Ingame
{ 
  // Ingame variables.
  int location = -1; // What wind the player has. Initialise it with a value of -1 to allow easy assert(ingame.location >= 0).
  ClosedHand closedHand; // The closed hand that can be changed. The discards are from here.
  OpenHand openHand; // The open pons/chis/kans 
  Tile[]  discards; // All of the personal discards.
  private Tile last_tile;  // The last tile, to determine whether or not this is a tsumo or a ron.
  bool isNagashiMangan = true;
  bool isRiichi = false;
  bool isDoubleRiichi = false;
  bool isFirstTurn = true;
  bool isTenpai = false;
  int pons=0; // Amount of open pons.
  int chis=0; // Amount of open chis.

  this(int wind)
  {
    this.location = wind;
    this.closedHand = new ClosedHand;
    this.openHand = new OpenHand;
  }

  public int getWind()
  {
    return location;
  }


/*
   Normal dibsing functions.
*/

  bool isPonnable(const ref Tile discard)
  {
    int i=0;
    foreach(tile; closedHand.tiles)
    {
      if(is_equal(tile, discard))
      {
        if((i+1) < closedHand.tiles.length)
        {
          if(is_equal(closedHand.tiles[i+1], discard))
          {
            return true;
          }
          else
          {
            return false;
          }
        }
      }
      ++i;  
    }
    return false;
  }

/*
   Functions related to the mahjong call.
*/

  bool checkTenpai()
  { /*
      Check whether a player sits tempai. Add one of each tile to the hand to see whether it will be a mahjong hand.
    */
    bool isTenpai = false;
    auto tile = new Tile;
    for(int t = types.min; t <= types.max; ++t)
    {
      tile.type = t;
      for(int i = characters.min; i <= characters.max; ++i)
      {
        tile.value = i;
        Tile[] temphand = closedHand.tiles ~ tile;
        if(scan_hand(temphand, chis, pons))
        {
          isTenpai = true;
        }

      }
    }
    this.isTenpai = isTenpai;
    return isTenpai;
  }

  public bool isFuriten()
  {
     foreach(tile; discards)
     {
       if(scan_hand(closedHand.tiles ~ tile, pons, chis))
       {
          return true;
       }
     }
     return false;
  }

  public bool isRonnable(ref Tile discard)
  {
    return scanHand(closedHand.tiles ~ discard) && !isFuriten ;
  }

  public bool isMahjong()
  {
     return scanHand(closedHand.tiles);
  }

  private bool scanHand(Tile[] set)
  {
     return .scan_hand(set, pons, chis);
     //FIXME: take into account yaku requirement.
  }

/*
   Discard things you no longer need.
*/

  void discard(ulong discardedNr)
  {    
    take_out_tile(closedHand.tiles, discards, discardedNr);
    discards[$-1].origin = location; // Sets the tile to be from the player who discarded it.
    discards[$-1].open;
    if( (!isHonour(discards[$-1])) && (!isTerminal(discards[$-1])) )
    {
      if(isNagashiMangan)
      {
        writeln(cast(kanji)location, " has lost Nagashi Mangan!");
      }
      isNagashiMangan = false;
    }
  }
  void discard(Tile discardedTile)
  {
     ulong i = 0;
     bool found = false;
     foreach(tile; closedHand.tiles)
     {
        if(is_identical(tile,discardedTile))
        {
           found = true;
           discard(i);
           break;
        }
        ++i;
     }
     if(!found)
     {
        throw new Exception("Identical tiles not found!");
     }
  }
  public ref Tile getLastDiscard()
  {
     return discards[$-1];
  }
  public ref Tile getLastTile()
  {
     return last_tile;
  }

  public void closeHand()
  {
    closedHand.closeHand;
  }
  public void showHand()
  {
    closedHand.showHand;
  }
  public void drawTile(ref Wall wall)
  {
    closedHand.drawTile(wall);
    last_tile = closedHand.getLastTile;
  }
/*
   Graphical drawing.
*/
  public void draw(ref RenderWindow window, const int playLoc)
  {
     closedHand.draw(window, playLoc);
     openHand.draw(window);
     drawDiscards(window);
  }
  private void drawDiscards(ref RenderWindow window)
  {
     foreach(tile; discards)
     {
        tile.draw(window);
     }
  }

}

class ClosedHand : Hand
{
  void place(const int playLoc)
  {
    /*
       Place the closed hand between two avatars.
    */
    sort_hand(tiles);
    int i = 0;
    foreach(stone; tiles)
    { 
      stone.setPosition(calculatePosition(tiles.length, playLoc, i));
      stone.rotateToPlayer(playLoc);
      ++i;
    }
  }

  private Vector2f calculatePosition(const size_t amountOfTiles, const int playLoc, const int i)
  {
    float[2] position = [width/2, height/2];
    float centering = (width - iconSpacing - amountOfTiles * tile.displayWidth)/2.; // Center the hand between two avatars
    float[2] movement;
    movement[0] = centering + i * tile.displayWidth - position[0];
    movement[1] = height/2 - iconSize; // Align the top of the tiles with the top of the own avatar.
    moveToPlayer(position, movement, playLoc);
    return Vector2f(position[0], position[1]);
  }

  public void closeHand()
  {
     foreach(tile; tiles)
     {
        tile.close;
     }
  }
  public void showHand()
  {
     foreach(tile; tiles)
     {
        tile.open;
     }
  }
  
  public void drawTile(ref Wall wall)
  {
    tiles ~= wall.drawTile;
    selectDrawnTile();
  }
  public Tile getLastTile()
  {
    return tiles[$-1];
  }

  public void draw(ref RenderWindow window, const int playLoc)
  {
     place(playLoc);
     selectOpt();
     foreach(tile; tiles)
     {
       tile.draw(window);
     }
  }

  public void selectDrawnTile()
  {
     auto drawnTile = tiles[$-1];
     sort_hand(tiles);
     for(int i = 0; i < tiles.length; ++i)
     {
       if(is_identical(tiles[i], drawnTile))
       {
          changeOpt(i);
          break;
       }
     }
  }

  public void open()
  {
    foreach(tile; tiles)
    {
       tile.open;
    }
  }
  public void close()
  {
    foreach(tile; tiles)
    {
       tile.close;
    }
  }
}

struct Selection
{
  RectangleShape visual;
  int position;
}

class OpenHand
{
  Tile[][amountOfSets] tiles;
  RectangleShape[3] selections;

  void initialiseSelections()
  {
    foreach(rectangle; selections)
    {
      rectangle = new RectangleShape;
      rectangle.fillColor = Color.Yellow;
      rectangle.size = tileSelectionSize;
    }
  }

  void resetSelections()
  {
    foreach(rectangle; selections)
    {
      rectangle.position = Vector2f(0,0);
      rectangle.size = Vector2f(0,0);
    }
  }

  void placeKanSelections(Tile[] hand, Tile dibsable)
  {
    placeIdenticals(hand, dibsable, 4);
  }

  void placePonSelections(Tile[] hand, Tile dibsable)
  {
    placeIdenticals(hand, dibsable, 3);
  }

  void placePairSelections(Tile[] hand, Tile dibsable)
  {
    placeIdenticals(hand, dibsable, 2);
  }

  void placeIdenticals(Tile[] hand, Tile dibsable, int amountOfIdenticals)
  {
    resetSelections;
    int i = 0;
    foreach(tile; hand)
    {
      if(is_equal(tile, dibsable))
      {
        selectTile(tile, i); 
        ++i;
        if(!(i < amountOfIdenticals-1))
        {
          break;
        }
      }
    }
  }

  void selectTile(Tile tile, const ref int i)
  {
    FloatRect position = tile.getGlobalBounds;
    selections[i].position = Vector2f(position.left - selectionMargin, position.top - selectionMargin);
    selections[i].size = Vector2f(position.width + 2*selectionMargin, position.height + 2*selectionMargin);
  }

  // FIXME: what is this function doing here?
  bool navigate(int key, ref Metagame meta)
  {
     bool isClaimed = false;
     enum chi {next = 1, prev = -1}
     switch(key)
     {
       case Keyboard.Key.Left:
         if(meta.chiable)
         {
           navigateChi(chi.prev, meta);
         }
         break;
       case Keyboard.Key.Right, Keyboard.Key.Space:
         if(meta.chiable)
         {
           navigateChi(chi.next, meta);
         }
         break;
       case Keyboard.Key.Return:
         isClaimed = true;
         return isClaimed;
       default:
         break;
     }
     return isClaimed;
  }

  void navigateChi(int direction, ref Metagame meta)
  {
//TODO FIXME
  }
 
  public void drawSelections(ref RenderWindow window)
  {
     foreach(rectangle; selections)
     {
        window.draw(rectangle);
     }
  } 

  FloatRect getGlobalBounds(int i)
  in
  { // Assert i is in the range.
    assert(i < amountOfSets);
    assert(i >= 0);
  }
  body
  {
    return calcGlobalBounds(tiles[][i]);
  }

  public void draw(ref RenderWindow window)
  {
     foreach(set; tiles)
     {
       foreach(tile; set)
       {
         tile.draw(window);
       }
     }
  }
}

class Hand : Selectable!Tile
{
   alias tiles = opts;
}

class MainMenu : Menu
{
   Sprite[] optSprites;
   Texture[] optTextures;
   ubyte[] opacities;
   
   void addOption(dstring text, string filename, IntRect range)
   { // Add an option to the menu and do all bureaucratic bullshit.
     auto texture = new Texture;
     auto sprite = new Sprite;
     load(texture, sprite, filename, range.left, range.top, range.width, range.height);
     pix2scale(sprite, width, height);
     optSprites ~= sprite;
     optTextures ~= texture;
     super.addOption(text);
     opacities ~= 0;
   }

   void changeMenuBackground()
   {
      selectOpt;
      changeOpacity;
      applyColors;
   }
   void changeOpacity()
   {
     .changeOpacity(opacities, to!int(opts.length), selection.position);
   }
   void applyColors()
   {
      for(int i = 0; i < opts.length; ++i)
      {
        optSprites[i].color = Color(255,255,255,opacities[i]);
      }
   }

  /*
     Draw functions.
  */
   void drawBg(ref RenderWindow window)
   {
     foreach(bgImg; optSprites)
     {
       window.draw(bgImg);
     }
   }
   override void draw(ref RenderWindow window)
   {
      drawBg(window);
      super.draw(window);
   }
}

class Menu : Selectable!Text
{
   void addOption(dstring text)
   {
     auto opt = new Text;
     with(opt)
     {
        setFont(menuFont);
        setString(text);
        setCharacterSize(32);
        setColor(Color.Black);
        position = Vector2f(200,0);
     }   
     CenterText(opt,"horizontal");
     opts ~= opt;
   }

   void construct()
   in
   {
     assert(opts.length > 0);
   }
   body
   {
     /*
       Take care of the layout of the menu. For now, let all menus begin at a set height and be centered.
     */
     enum MenuTop = 250; // Distance to the top of the screen.
     enum MenuSpacing = 20; // Distance between two text boxes.
     FloatRect size = opts[0].getGlobalBounds();
     uint i = 0;
     foreach(opt; opts)
     {
       float ypos;
       ypos = MenuTop + (size.height + MenuSpacing)*i;
       opt.position = Vector2f(0, ypos);
       CenterText(opt, "horizontal");
       ++i;
     } 
   }


   void draw(ref RenderWindow window)
   {
      drawSelection(window);
      drawOpts(window);
   }
  void drawSelection(ref RenderWindow window)
  {
     window.draw(selection.visual);
  }
  void drawOpts(ref RenderWindow window)
   {
     foreach(opt; opts)
     {
       window.draw(opt);
     }
   }
}

class Selectable(T)
{
   T[] opts;
   Selection selection;
   
   this()
   {
     // Also initialise the selection.
     this.selection = Selection(new RectangleShape, 0);
     selection.visual.fillColor = Color.Red;
   }


  bool navigate(int key)
  {
     bool isEntered = false; // Check whether the enter button is pressed.
     switch(key)
     {
       case Keyboard.Key.Up, Keyboard.Key.Left:
         --selection.position;
         break;
       case Keyboard.Key.Down, Keyboard.Key.Right:
         ++selection.position;
         break;
       case Keyboard.Key.Return:
         isEntered = true;
         return isEntered;
       default:
         break;
     }
     selectOpt;
     return isEntered;
  }

  void selectOpt()
  {
    // Firstly check whether the selection does not fall out of bounds.
    correctOutOfBounds(selection.position, opts.length);
    // Construct the selection rectangle.
    FloatRect optPos = opts[selection.position].getGlobalBounds();
    selection.visual.position = Vector2f(optPos.left - selectionMargin, optPos.top - selectionMargin);
    selection.visual.size = Vector2f(optPos.width + 2 * selectionMargin, optPos.height + 2 * selectionMargin);
  }

  void changeOpt(const int i)
  {
    // Change the option to a given value i.
    selection.position = i;
    selectOpt;
  }

  FloatRect getGlobalBounds()
  {
    return calcGlobalBounds(opts);
  }

}

FloatRect calcGlobalBounds(T) (T opts)
{
    /*
      Get the rectangular global bounds of a given system.
    */
    FloatRect bounds;
    if(opts.length == 0)
    {
      bounds.top = 0;
      bounds.left = 0;
      bounds.height = 0;
      bounds.width = 0;
      return bounds;
    }
    bounds.top = float.max;
    bounds.left = float.max;
    bounds.height = 0;
    bounds.width = 0;
    foreach(opt; opts)
    {
       auto localBounds = opt.getGlobalBounds; // Nice naming, eh?
       if(localBounds.left < bounds.left)
       {
          bounds.left = localBounds.left;
       }
       if(localBounds.top < bounds.top)
       {
          bounds.top = localBounds.top;
       }
    }
    foreach(opt; opts)
    {
       auto localBounds = opt.getGlobalBounds; // Nice naming, eh?
       if((localBounds.left + localBounds.width - bounds.left) > bounds.width)
       {
          bounds.width = localBounds.left + localBounds.width - bounds.left;
       }
       if((localBounds.top + localBounds.height - bounds.top) > bounds.height)
       {
          bounds.height = localBounds.top + localBounds.height - bounds.top;
       }
    }
    return bounds;
}


