module mahjong.domain.metagame;

import std.algorithm;
import std.experimental.logger;
import std.random;
import std.conv;
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
	Player[] players; 

	Player currentPlayer() @property 
	{ 
		return _turn == -1 ? null : players[_turn]; 
	}

	Player currentPlayer(Player player) @property
	{
		_turn = players.countUntil!(p => p == player);
		return player;
	} 

	auto otherPlayers() @property
	{
		auto currentPlayer = this.currentPlayer;
		return players.filter!(p => p != currentPlayer);
	}

	Wall wall;
	PlayerWinds leadingWind;
	private int _initialWind;
	uint round;

	this(Player[] players)
	{
		this.players = players;
		initialise;
	}

	bool hasStarted()
	{
		return _status != Status.NewGame;
	}
	private void initialise()
	{
		info("Initialising metagame");
		placePlayers;
		_initialWind = uniform(0, players.length).to!int; 
		info("Initialised metagame");
	}

	/++
	 + Sets up the round such that it can be started.
	 +/
	void nextRound()
	{
		info("Moving to the next round");
		setPlayers;
		removeTurnPlayer;
	}

	private void setPlayers()
	{
		_status = Status.NewGame;
		leadingWind = PlayerWinds.east;
		round = 1;
		info("Setting up the game");
		setPlayersGame;
		trace("Setting up the wall.");
		wall = getWall;
		wall.setUp;
		info("Preparations are finished.");
	}

	/++
	 + Begins the round, assuming that it is initialised.
	 +/
	void beginRound()
	{
		wall.dice;
		distributeTiles;
		setTurnPlayerToEast;
		_status = Status.Running;

	}
	private void setPlayersGame()
	{
		foreach(int i, player; players) // Re-initialise the players' game.
		{ 
			player.startGame((_initialWind + i) % gameOpts.amountOfPlayers);
		}
	}
   
	protected Wall getWall()
	{
		return new Wall;
	}

   private void placePlayers()
   { 
		foreach(i, player; players)
		{
        	trace("Placing player \"", player.name, "\" (", i, ")");
        	player.playLoc = i.to!int;

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

	private size_t _turn = 0; 
	private Status _status = Status.SetUp;
	const Status status() @property
	{
		return _status;
	}

	private Phase _phase = Phase.Draw;

	private void setTurnPlayerToEast() 
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

	private void removeTurnPlayer()
	{
		_turn = -1;
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

	bool isAbortiveDraw() @property
	{
		return false;
	}

	bool isExhaustiveDraw() @property
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

	Phase phase() @property
	{
		return _phase;
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
	this(Player[] players)
	{
		super(players);
	}

	override Wall getWall()
	{
		return new BambooWall;
	}
}

class EightPlayerMetagame : Metagame
{
	this(Player[] players)
	{
		super(players);
	}

	override Wall getWall()
	{
		return new EightPlayerWall;
	}
}



