module mahjong.domain.ingame;

import std.experimental.logger;
import dsfml.graphics.renderwindow;
import mahjong.domain.closedhand;
import mahjong.domain.enums.tile;
import mahjong.domain.openhand;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.mahjong;
import mahjong.graphics.enums.kanji;

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
    for(int t = Types.min; t <= Types.max; ++t)
    {
      tile.type = t;
      for(int i = Numbers.min; i <= Numbers.max; ++i)
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
        info(cast(Kanji)location, " has lost Nagashi Mangan!");
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

	void closeHand()
	{
		closedHand.closeHand;
	}
	
	void showHand()
	{
		closedHand.showHand;
	}
	
	void drawTile(ref Wall wall)
	{
		closedHand.drawTile(wall);
		last_tile = closedHand.getLastTile;
	}

}