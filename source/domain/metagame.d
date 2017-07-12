module mahjong.domain.metagame;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.random;
import std.range;
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

	size_t amountOfPlayers() @property pure const
	{
		return players.length;
	}

	Wall wall;
	private PlayerWinds _leadingWind;
	PlayerWinds leadingWind() @property pure const
	{
		return _leadingWind;
	}
	private const Player _initialEastPlayer;
	private int _initialWind;

	private uint _round = 1;
	uint round() @property pure const
	{
		return _round;
	}

	private size_t _counters = 0;
	size_t counters() @property pure const
	{
		return _counters;
	}

	this(Player[] players)
	{
		this.players = players;
		info("Initialising metagame");
		placePlayers;
		_initialWind = uniform(0, players.length).to!int; 
		_initialEastPlayer = getEastPlayer;
		_leadingWind = PlayerWinds.east;
		info("Initialised metagame");
	}

	private Player getEastPlayer()
	{
		return players[($-_initialWind)%$];
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
	in
	{
		assert(!isGameOver, "Cannot start a new round when the game is over.");
	}
	body
	{
		info("Initializing the next round");
		startPlayersGame;
		setUpWall;
		removeTurnPlayer;
	}

	private void startPlayersGame()
	{
		foreach(int i, player; players)
		{ 
			auto wind = ((_initialWind + i) % players.length).to!PlayerWinds;
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
		++_round;
		auto data = constructMahjongData;
		applyTransactions(data);
		moveWinds;
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

	private void moveWinds()
	{
		if(!needToMoveWinds) 
		{
			++_counters;
			return;
		}
		_counters = 0;
		_initialWind = ((_initialWind - 1 + players.length) % players.length).to!int;
		if(_initialEastPlayer == getEastPlayer)
		{
			_leadingWind = (_leadingWind + 1).to!PlayerWinds;
			_round = 1;
		}
	}

	private bool needToMoveWinds()
	{
		return !players.first!(p => p.isEast).isMahjong;
	}

	bool isGameOver()
	{
		return _leadingWind > gameOpts.finalLeadingWind;
	}
	/*
	 The game itself.
	 */

	private size_t _turn = 0; 

	private void setTurnPlayerToEast() 
	{
		foreach(i, player; players)
		{
			if(player.isEast)
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
			_turn = (_turn + 1) % players.length;
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

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new BambooOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto players = [player1, player2];
	auto metagame = new Metagame(players);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = players[metagame._initialWind];
	eastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	assert(eastPlayer.isEast, "the east player was mahjong, the turns should not have advanced");
	assert(1 == metagame.counters, "A counter should have been placed");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new BambooOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto players = [player1, player2];
	auto metagame = new Metagame(players);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = players[metagame._initialWind];
	auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
	nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	assert(nonEastPlayer.isEast, "the non east player was mahjong, the turns should have advanced");
	assert(!eastPlayer.isEast, "the non east player was mahjong, the turns should have advanced");
	assert(metagame.round == 2, "The round counter should have been upped.");
	assert(metagame.counters == 0, "As the turn advanced, there are no more counters");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new BambooOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto players = [player1, player2];
	auto metagame = new Metagame(players);
	metagame.initializeRound;
	metagame.beginRound;
	foreach(i; 0..2)
	{
		auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
		nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
		metagame.finishRound;
		metagame.initializeRound;
		metagame.beginRound;
	}
	assert(metagame.leadingWind == PlayerWinds.south, "After the first east player becomes east again, the leading wind should swap.");
	assert(metagame.round == 1, "The round should have been reset");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new BambooOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto player3 = new Player(new TestEventHandler);
	auto player4 = new Player(new TestEventHandler);
	auto players = [player1, player2, player3, player4];
	auto metagame = new Metagame(players);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = metagame.currentPlayer;
	auto southPlayer = metagame.nextPlayer;
	assert(southPlayer.wind == PlayerWinds.south, "Sanity check");
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	assert(southPlayer.isEast, "the south player was mahjong, the turns should have advanced such that the south player is now east");
	assert(!eastPlayer.isEast, "the non east player was mahjong, the turns should have advanced");
	assert(eastPlayer.wind == PlayerWinds.north, "east is degraded to north");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new BambooOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto player3 = new Player(new TestEventHandler);
	auto player4 = new Player(new TestEventHandler);
	auto players = [player1, player2, player3, player4];
	auto metagame = new Metagame(players);
	metagame.initializeRound;
	metagame.beginRound;
	foreach(i; 0..3)
	{
		metagame.finishRound;
		metagame.initializeRound;
		metagame.beginRound;
	}
	assert(metagame.leadingWind == PlayerWinds.east, "With three east losses, the leading wind should not have changed");
	assert(metagame.round == 4, "we are going to the fourth east round.");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	import mahjong.engine.opts;
	gameOpts = new BambooOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto players = [player1, player2];
	auto metagame = new Metagame(players);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = players[metagame._initialWind];
	eastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	// East does not win.
	metagame.finishRound;
	assert(metagame.counters == 0, "The amount of counters should have been reset");
}

unittest
{
	import core.exception;
	import std.exception;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	gameOpts = new DefaultGameOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto player3 = new Player(new TestEventHandler);
	auto player4 = new Player(new TestEventHandler);
	auto players = [player1, player2, player3, player4];
	auto metagame = new Metagame(players);
	metagame.initializeRound;
	metagame.beginRound;
	foreach(i; 0..7)
	{
		auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
		nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
		metagame.finishRound;
		assert(!metagame.isGameOver, "There are still turns left to play!");
		metagame.initializeRound;
		metagame.beginRound;
	}
	auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
	nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	assert(metagame.isGameOver, "The game should have been finished after 2x 4 rounds of non-east wins.");
	assertThrown!AssertError(metagame.initializeRound, "Attempting to start a new round should be blocked");

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



