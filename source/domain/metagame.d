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
import mahjong.share.range;

class Metagame
{
	Player[] players; 

	Player currentPlayer() @property 
	{ 
		return _turn == -1 ? null : players[_turn]; 
	}

	Player currentPlayer(Player player) @property
	{
		_turn = players.indexOf(player);
		return player;
	}

	const(Player) nextPlayer() @property pure const
	{
		return players[(_turn+1)%$];
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
        	trace("Placing player \"", player.name.to!string, "\" (", i, ")");
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
		}
		else
		{
			info("Player ", cast(Kanji)currentPlayer.getWind, " chombo'd");
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

	deprecated("Move to exhaustive draw flow.")
	private void exhaustiveDraw()
	{
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

unittest
{
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto player3 = new Player(new TestEventHandler);
	auto metagame = new Metagame([player, player2, player3]);
	metagame.currentPlayer = player;
	assert(metagame.currentPlayer == player, "The current player should be set and identical to the value set");
	assert(metagame.nextPlayer == player2, "If it is player 1's turn, player 2 should be next.");
	metagame.currentPlayer = player3;
	assert(metagame.nextPlayer == player, "If it is player 3's turn, the next player should loop back to 1");
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



