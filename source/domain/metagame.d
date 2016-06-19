module mahjong.domain.metagame;

import std.experimental.logger;
import std.random;
import std.conv;
import std.signals;
import std.uuid;

import mahjong.domain.enums.game;
import mahjong.domain.enums.tile;
import mahjong.domain.enums.wall;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;
import mahjong.engine.opts.opts;
import mahjong.graphics.enums.game;
import mahjong.graphics.enums.kanji;

class Metagame
{
   /*
     Preparation of the game.
   */

	Player currentPlayer() { return players[_turn]; }
	Player[] players; 
	Wall wall;

	bool hasStarted()
	{
		return _status != Status.NewGame;
	}
	void initialise()
	{
		info("Initialising metagame");
		constructPlayers;
		trace("Constructed players");
		setPlayers(uniform(0, gameOpts.amountOfPlayers));
		info("Initialised metagame");
	}
	void nextRound()
	{
		info("Moving to the next round");
		setPlayers(players[playerLocation.bottom].getWind);
		emit;
	}
	
	mixin Signal!();
	
	private void setPlayers(int initialWind)
	{
		_status = Status.NewGame;
		info("Setting up the game");
		setPlayersGame(initialWind);
		trace("Setting up the wall.");
		wall = getWall;
		wall.setUp;
		info("Preparations are finished.");
	}
	void beginGame()
	{
		wall.dice;
		distributeTiles;
		//firstTurn;
		_status = Status.Running;

	}
   private void setPlayersGame(int initialWind)
   {
     foreach(player; players) // Re-initialise the players' game.
     { 
       player.firstGame(initialWind % gameOpts.amountOfPlayers);
       ++initialWind;
     }
   }

   void reset()
   { 
     int initialWind = uniform(0, gameOpts.amountOfPlayers); 
     setPlayers(initialWind);
   }
   
	protected Wall getWall()
	{
		return new Wall;
	}

   private void constructPlayers()
   { // FIXME: Encapsulate this in the player class.
     for(int i=0; i < gameOpts.amountOfPlayers;++i)
      {
      // TODO: Idea: Make a number of preset profiles that can be loaded. E.g. player1avatar = Sakura.avatar;
        trace("Constructing player ", i);
        auto player = new Player;
        player.playLoc = i;
        trace(player.name);
        players ~= player;
      }
   }

   private void distributeTiles()
   {
     for(int i = 0; i < 12/tilesAtOnce; ++i)
     {
       distributeXTiles(tilesAtOnce);
     }
     distributeXTiles(1);
   }
   private void distributeXTiles(int amountOfTiles)
   {
       foreach(player; players)
       { // TODO: update such that distribution begins with East.
         for(int i = 0; i < amountOfTiles; ++i)
         {
            player.drawTile(wall);
         }
       }
   }

   /*
     The game itself.
   */

   private int _turn = 0; // Whose turn it is.
   private int _status = Status.SetUp;

   private Phase _phase = Phase.Draw;


   private void firstTurn() // Start at East.
   {
     int i;
     foreach(player; players)
     {
       if(player.game.wind == Winds.east)
       {
         _turn = i;
         _phase = Phase.Draw;
         break;
       }
       ++i;
     }
   }

	void drawTile()
	{ 
		currentPlayer.drawTile(wall);
		_phase = Phase.Discard;
	}
	
	void tsumo()
	{
		flipOverWinningTiles();
		if(hasMahjong)
		{
			info("Player ", cast(Kanji)currentPlayer.getWind, " won");
		}
		else
		{
			info("Player ", cast(Kanji)currentPlayer.getWind, " chombo'd");
		}
		_status = Status.Mahjong;
	}

   int[] discardTile(T) (T discard)
   {
     currentPlayer.discard(discard);
     return isPonnable(currentPlayer.getLastDiscard);
   }

   private void endPhase()
   {  //FIXME: should not be called when there is a claimable tile.
     if(_phase == Phase.End)
     {
       if(advanceTurn)
       {
         _phase = Phase.Draw;
       }
     }
   }

   bool advanceTurn()
   {
     if(wall.length > deadWallLength)
     {
       nextTurn();
       return true;
     }
     else
     {
       exhaustiveDraw;
       return false;
     }
   }

   void nextTurn()
   {
     ++_turn;
     _turn = _turn % gameOpts.amountOfPlayers;
   }



   private void exhaustiveDraw()
   {
     _status = Status.ExhaustiveDraw;
     checkNagashiMangan;
     checkTenpai;
   }
   private void checkNagashiMangan()
   {
     foreach(player; players)
     {
       if(player.isNagashiMangan)
       {
         // Go ro results screen.
         _status = Status.Mahjong;
         info("Nagashi Mangan!");
       }
     }
   }
   private void checkTenpai()
   {
     foreach(player; players)
     {
       if(player.isTenpai)
       {
         player.showHand;
         info(cast(Kanji)player.getWind, " is tenpai!");
       }
       else
       {
         player.closeHand;
       }
     }
   }

	Phase phase()
	{
		return _phase;
	}
	bool isPhase(Phase phase)
	{
		return _phase == phase;
	}

	bool isTurn(UUID playerId)
	{
		return currentPlayer.id == playerId;
	}

   /*
     Random useful functions.
   */

   private bool hasMahjong()
   {
     return currentPlayer.isMahjong;
   }

   private void flipOverWinningTiles()
   {
     foreach(player; players)
     {
       if(player.isMahjong)
          player.showHand;
       else
          player.closeHand; 
     }
   }

   /*
      Dump everything related to claiming tiles here.
   */ 

   private bool _ponnable = false;
   private bool _chiable = false;
   private bool _kannable = false;
   private bool _ronnable = false;

   bool ponnable() { return _ponnable; }
   bool chiable() { return _chiable; }
   bool kannable() { return _kannable; }
   bool ronnable() { return _ronnable; }

   private int[] canClaimTile = [-1]; // The playerLocations that can claim a tile.

   private bool claimable()
   {
     return ponnable || chiable || kannable || ronnable;
   }
   private int[] isPonnable(const Tile discard)
   { /*
        Checks whether a discard can be ponned and returns the player location (.bottom, .right, .etc). If the tile cannot be ponned, it returns a -1.
     */
     // Start checking for pons at next player.
     for(int i = _turn+1; i < _turn + gameOpts.amountOfPlayers; ++i)
     {
        if(players[i % gameOpts.amountOfPlayers].isPonnable(discard))
        {
          trace(cast(playerLocation)(i % gameOpts.amountOfPlayers), " could have ponned that one.");
          break;
        }
     }
     canClaimTile = [-1];
     return canClaimTile;
   } 

   private int[] isRonnable(Tile discard)
   { /*
       Checks whether the discard can be ronned by any player.
     */
     // Start checking for rons at the next player.
     _ronnable = false;
     canClaimTile = [];
     for(int i = _turn + 1; i < _turn + gameOpts.amountOfPlayers; ++i)
     {
        int pl = i % gameOpts.amountOfPlayers;
        if(players[pl].isRonnable(discard))
        {
           _ronnable = true;
           canClaimTile ~= pl;
           trace(cast(playerLocation) pl , "can ron it!"); 
        }
     }

     if(!_ronnable)
        canClaimTile = [-1];
     return canClaimTile;
   } 
}

class BambooMetagame : Metagame
{
	override Wall getWall()
	{
		return new BambooWall;
	}
}

class EightPlayerMetagame : Metagame
{
	override Wall getWall()
	{
		return new EightPlayerWall;
	}
}



