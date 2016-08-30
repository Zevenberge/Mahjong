module mahjong.domain.metagame;

import std.experimental.logger;
import std.random;
import std.conv;
import std.signals;
import std.uuid;

import mahjong.domain.enums.game;
import mahjong.domain.enums.tile;
import mahjong.domain.enums.wall;
import mahjong.domain;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;
import mahjong.engine.opts;
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
	PlayerWinds leadingWind;
	uint round;

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
		leadingWind = PlayerWinds.east;
		round = 1;
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
		setFirstTurn;
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

	private int _turn = 0; 
	private Status _status = Status.SetUp;
	const Status status() @property
	{
		return _status;
	}

	private Phase _phase = Phase.Draw;

	private void setFirstTurn() 
	{
		foreach(i, player; players)
		{
			if(player.game.wind == Winds.east)
			{
				_turn = i.to!int;
				_phase = Phase.Draw;
				break;
			}
		}
	}

	void tsumo(Player player)
	in
	{
		assert(player == currentPlayer);
	}
	body
	{
		flipOverWinningTiles();
		if(player.isMahjong)
		{
			info("Player ", cast(Kanji)currentPlayer.getWind, " won");
			_status = Status.Mahjong;
		}
		else
		{
			info("Player ", cast(Kanji)currentPlayer.getWind, " chombo'd");
			_status = Status.AbortiveDraw;
		}
	}

	void advanceTurn()
	{
		if(isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
			exhaustiveDraw;
		}
		else
		{
			trace("Advancing turn.");
			_phase = Phase.Draw;
			_turn = (_turn + 1) % gameOpts.amountOfPlayers;
		}
	}

	bool isAbortiveDraw()
	{
		return false;
	}

	bool isExhaustiveDraw()
	{
		return wall.length <= gameOpts.deadWallLength;
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



