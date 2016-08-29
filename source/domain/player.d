module mahjong.domain.player;

import std.string;
import std.uuid;

import mahjong.domain.enums.game;
import mahjong.domain.ingame;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.opts;



class Player
{ // General variables.
	UUID id;
	dchar[] name = "Cal"d.dup;

	int playLoc = -10;
	int score; 

	Ingame game; // Resets after every round.


	this()
	{
		id = randomUUID;

	}
	this(dchar[] name)
	{
		this.name = name;
		this();
	}

	void nextRound(bool passWinds)
	{
		int wind = (game.getWind + passWinds ? 1 : 0) % gameOpts.amountOfPlayers;
		startGame(wind);
	}

	private void startGame(int wind)
	{
		game = new Ingame(wind);
	}

	void firstGame(int initialWind)
	{
		score = gameOpts.initialScore;
		startGame(initialWind);
	}

  int getWind()
  {
    return game.getWind();
  }

  void drawTile(ref Wall wall)
  {
     this.game.drawTile(wall);
  }

  Tile getLastDiscard()
  {
     return game.getLastDiscard;
  }
  Tile getLastTile()
  {
     return game.getLastTile;
  }

  /*
     Functions with regard to placing tiles and displays.
  */

  public void discard(T) (T disc)
  {
     game.discard(disc);
  }

  void placeRiichi()
  {

  }

   Player dup()
   {
     return new Player(name);
   }

   override string toString() const
   {
     return(format("%s-san",name));
   }

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

	void showHand()
	{
		game.showHand();
	}
	void closeHand()
	{
		game.closeHand();
	}
}


