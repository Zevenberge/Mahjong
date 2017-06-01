module mahjong.domain.player;

import std.experimental.logger;
import std.string;
import std.uuid;

import mahjong.domain.enums.game;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow;
import mahjong.engine.opts;

class Player
{ // General variables.
	UUID id;
	dstring name = "Cal"d;

	int playLoc = -10;
	int score; 

	Ingame game; // Resets after every round.
	GameEventHandler eventHandler; // Allows for distribution of the flow logic

	this(GameEventHandler eventHandler)
	{
		id = randomUUID;
		score = gameOpts.initialScore;
		this.eventHandler = eventHandler;
	}
	this(GameEventHandler eventHandler, dstring name)
	{
		this.name = name;
		this(eventHandler);
	}

	void nextRound(bool passWinds)
	{
		int wind = (game.getWind + passWinds ? 1 : 0) % gameOpts.amountOfPlayers;
		startGame(wind);
	}

	void startGame(int wind)
	{
		trace("Starting game for ", wind);
		game = new Ingame(wind);
	}

	int getWind()
	{
		if(game is null) return -1;
		return game.getWind();
	}

	void drawTile(Wall wall)
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

	public void discard(Tile disc)
	{
		game.discard(disc);
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

	bool isChiable(const Tile discard, const Metagame metagame) pure const
	{
		if(metagame.nextPlayer.id != this.id) return false;
		return game.isChiable(discard);
	}

	void chi(Tile discard, ChiCandidate otherTiles)
	{
		game.chi(discard, otherTiles);
	}

	bool isPonnable(const Tile discard) pure
	{
		return game.isPonnable(discard);
	}

	void pon(Tile discard)
	{
		game.pon(discard);
	}

	bool isKannable(const Tile discard) pure
	{
		return game.isKannable(discard);
	}

	void kan(Tile discard, Wall wall)
	{
		game.kan(discard, wall);
	}

	bool isRonnable(const Tile discard) pure
	{ 
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

	override bool opEquals(Object o)
	{
		auto p = cast(Player)o;
		if(p is null) return false;
		return p.id == id;
	}
}

unittest
{
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(1);
	assert(player.isPonnable(ponnableTile), "Expected the tile to be ponnable");
	auto nonPonnableTile = "🀃"d.convertToTiles[0];
	assert(!player.isPonnable(nonPonnableTile), "The tile should not have been ponnable");
}

unittest
{
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto player2 = new Player(new TestEventHandler);
	auto metagame = new Metagame([player, player2]);
	metagame.currentPlayer = player2;
	auto chiableTile = "🀕"d.convertToTiles[0];
	chiableTile.origin = new Ingame(1);
	assert(player.isChiable(chiableTile, metagame), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀓🀕"d.convertToTiles;
	chiableTile = "🀔"d.convertToTiles[0];
	chiableTile.origin = new Ingame(1);
	assert(player.isChiable(chiableTile, metagame), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀔🀕"d.convertToTiles;
	chiableTile = "🀓"d.convertToTiles[0];
	chiableTile.origin = new Ingame(1);
	assert(player.isChiable(chiableTile, metagame), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto nonChiableTile = "🀔"d.convertToTiles[0];
	nonChiableTile.origin = new Ingame(1);
	assert(!player.isChiable(nonChiableTile, metagame), "The tile should not have been chiable");
}

unittest
{
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀀🀁"d.convertToTiles;
	auto player2 = new Player(new TestEventHandler);
	auto metagame = new Metagame([player, player2]);
	metagame.currentPlayer = player2;
	auto nonChiableTile = "🀂"d.convertToTiles[0];
	nonChiableTile.origin = new Ingame(1);
	assert(!player.isChiable(nonChiableTile, metagame), "The tile should not have been chiable");
	player.game.closedHand.tiles = "🀄🀅"d.convertToTiles;
	nonChiableTile = "🀆"d.convertToTiles[0];
	nonChiableTile.origin = new Ingame(1);
	assert(!player.isChiable(nonChiableTile, metagame), "The tile should not have been chiable");
}

unittest
{
	void addTileToDiscard(Player player, Tile tile)
	{
		player.game.closedHand.tiles ~= tile;
		player.discard(tile);
	}
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d.convertToTiles;
	auto player2 = new Player(new TestEventHandler);
	auto metagame = new Metagame([player, player2]);
	metagame.currentPlayer = player2;
	auto ponnableTile = "🀐"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(1);
	assert(player.isRonnable(ponnableTile), "The tile should have been ronnable");
	addTileToDiscard(player, "🀐"d.convertToTiles[0]);
	assert(!player.isRonnable(ponnableTile), "The tile should have not been ronnable as the tile is included in the discards");
	addTileToDiscard(player, "🀖"d.convertToTiles[0]);
	assert(!player.isRonnable(ponnableTile), "The tile should have not been ronnable as the player is furiten");
}

unittest
{
	import std.exception;
	import mahjong.domain.exceptions;
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	auto tiles = "🀓🀔"d.convertToTiles;
	player.game.closedHand.tiles = tiles;
	auto candidate = ChiCandidate(tiles[0], tiles[1]);
	auto chiableTile = "🀕"d.convertToTiles[0];
	chiableTile.origin = new Ingame(1);
	player.chi(chiableTile, candidate);
	assert(player.game.closedHand.length == 0, "The tiles should have been removed from the hand,");
	assert(player.game.openHand.amountOfChis == 1, "The open hand should have one chi.");
	assert(player.game.openHand.sets.length == 1, "The open hand should have one set.");
	assertThrown!IllegalClaimException(player.chi(chiableTile, candidate), "With no tiles in hand, an exception should be thrown.");
}

unittest
{
	import std.exception;
	import mahjong.domain.exceptions;
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(1);
	player.pon(ponnableTile);
	assert(player.game.closedHand.length == 0, "The tiles should have been removed from the hand,");
	assert(player.game.openHand.amountOfPons == 1, "The open hand should have one pon.");
	assert(player.game.openHand.sets.length == 1, "The open hand should have one set.");
	assertThrown!IllegalClaimException(player.pon(ponnableTile), "With no tiles in hand, an exception should be thrown.");
}

unittest
{
	import std.array;
	import std.exception;
	import mahjong.domain.exceptions;
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto wall = new Wall;
	wall.setUp;
	wall.dice;
	auto initialWallLength = wall.length;
	auto lastTile = wall.tiles.back;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀕🀕🀕"d.convertToTiles;
	auto kannableTile = "🀕"d.convertToTiles[0];
	kannableTile.origin = new Ingame(1);
	player.kan(kannableTile, wall);
	assert(player.game.closedHand.length == 1, "The tiles should have been removed from the hand and one tile drawn from the wall.");
	assert(player.game.closedHand.tiles.front == lastTile, "The last tile of the wall should have been drawn");
	assert(wall.length == initialWallLength - 1, "The wall should have decreased by 1");
	assert(player.game.openHand.amountOfPons == 1, "The open hand should have one pon.");
	assert(player.game.openHand.amountOfKans == 1, "The open hand should have one kan.");
	assert(player.game.openHand.sets.length == 1, "The open hand should have one set.");
	assertThrown!IllegalClaimException(player.kan(kannableTile, wall), "With no tiles in hand, an exception should be thrown.");
}