module mahjong.domain.metagame;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.random;
import std.conv;
import std.uuid;

import mahjong.domain.enums;
import mahjong.domain;
import mahjong.engine.flow.mahjong;
import mahjong.engine.mahjong;
import mahjong.engine.opts;
import mahjong.engine.scoring;
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

	auto otherPlayers() 
	{
		auto currentPlayer = this.currentPlayer;
		return players.filter!(p => p != currentPlayer);
	}

	auto otherPlayers(const Player player) const
	{
		return players.filter!(p => p != player);
	}

	Wall wall;
	private PlayerWinds _leadingWind;
	PlayerWinds leadingWind() @property pure const
	{
		return _leadingWind;
	}
	private const Player _initialEastPlayer;
	private int _initialWind;
	uint round;

	this(Player[] players)
	{
		this.players = players;
		info("Initialising metagame");
		placePlayers;
		round = 1;
		_initialWind = uniform(0, players.length).to!int; 
		_initialEastPlayer = players[uniform(0, players.length)];
		_leadingWind = PlayerWinds.east;
		info("Initialised metagame");
	}

	private void placePlayers()
	{ 
		foreach(i, player; players)
		{
			trace("Placing player \"", player.name.to!string, "\" (", i, ")");
			player.playLoc = i.to!int;
		}
	}

	void initializeRound()
	{
		info("Initializing the next round");
		startPlayersGame;
		setUpWall;
		removeTurnPlayer;
	}

	private void startPlayersGame()
	{
		foreach(int i, player; players) // Re-initialise the players' game.
		{ 
			auto wind = ((_initialWind + i) % gameOpts.amountOfPlayers).to!PlayerWinds;
			player.startGame(wind);
		}
	}
	
	private void removeTurnPlayer()
	{
		_turn = -1;
	}

	private void setUpWall()
	{
		wall = getWall;
		wall.setUp;
	}

	protected Wall getWall()
	{
		return new Wall;
	}

	void beginRound()
	{
		wall.dice;
		distributeTiles;
		setTurnPlayerToEast;
	}

	private void distributeTiles()
	{
		for(int i = 0; i < 3; ++i)
		{
			distributeXTiles(4);
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

	void finishRound()
	{
		auto data = constructMahjongData;
		applyTransactions(data);
	}

	private void applyTransactions(const(MahjongData)[] data)
	{
		auto transactions = data.toTransactions(this);
		foreach(transaction; transactions)
		{
			auto player = players.first!(p => p == transaction.player);
			player.applyTransaction(transaction);
		}
	}
	/*
	 The game itself.
	 */

	private size_t _turn = 0; 

	private void setTurnPlayerToEast() 
	{
		foreach(i, player; players)
		{
			if(player.wind == Winds.east)
			{
				_turn = i.to!int;
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
			info("Player ", cast(Kanji)currentPlayer.wind, " won");
		}
		else
		{
			info("Player ", cast(Kanji)currentPlayer.wind, " chombo'd");
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
				info(cast(Kanji)player.wind, " is tenpai!");
			}
			else
			{
				player.closeHand;
			}
		}
	}

	bool isTurn(UUID playerId)
	{
		return currentPlayer.id == playerId;
	}

	const(MahjongData)[] constructMahjongData()
	{
		return players.map!((player){
				auto mahjongResult = scanHandForMahjong(player);
				return MahjongData(player, mahjongResult);
			}).filter!(data => data.result.isMahjong).array;
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



