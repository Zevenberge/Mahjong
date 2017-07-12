module mahjong.domain.player;

import std.experimental.logger;
import std.string;
import std.uuid;

import mahjong.domain.enums;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow;
import mahjong.engine.opts;
import mahjong.engine.scoring;

class Player
{ // General variables.
	const UUID id;
	dstring name = "Cal"d;

	int playLoc = -10;
	private int _score;
	int score() @property pure const
	{
		return _score;
	}

	Ingame game; // Resets after every round.
	alias game this;
	GameEventHandler eventHandler; // Allows for distribution of the flow logic

	this(GameEventHandler eventHandler)
	{
		id = randomUUID;
		_score = gameOpts.initialScore;
		this.eventHandler = eventHandler;
	}
	this(GameEventHandler eventHandler, dstring name)
	{
		this.name = name;
		this(eventHandler);
	}

	void startGame(PlayerWinds wind)
	{
		trace("Starting game for ", wind);
		game = new Ingame(wind);
	}

	int wind() @property pure const
	{
		if(game is null) return -1;
		return game.wind;
	}

	bool isChiable(const Tile discard, const Metagame metagame) pure const
	{
		if(metagame.nextPlayer.id != this.id) return false;
		return game.isChiable(discard);
	}

	void drawTile(Wall wall)
	{
		this.game.drawTile(wall);
	}

	void applyTransaction(const Transaction transaction)
	in
	{
		assert(transaction.player == this, "The transaction was applied to the wrong player.");
	}
	body
	{
		_score += transaction.amount;
	}

	override bool opEquals(Object o)
	{
		auto p = cast(Player)o;
		if(p is null) return false;
		return p.id == id;
	}

	override string toString() const
	{
		return(format("%s-san",name));
	}
}

unittest
{
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(PlayerWinds.south);
	assert(player.isPonnable(ponnableTile), "Expected the tile to be ponnable");
	auto nonPonnableTile = "🀃"d.convertToTiles[0];
	assert(!player.isPonnable(nonPonnableTile), "The tile should not have been ponnable");
}

unittest
{
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto player2 = new Player(new TestEventHandler);
	auto metagame = new Metagame([player, player2]);
	metagame.currentPlayer = player2;
	auto chiableTile = "🀕"d.convertToTiles[0];
	chiableTile.origin = new Ingame(PlayerWinds.south);
	assert(player.isChiable(chiableTile, metagame), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀓🀕"d.convertToTiles;
	chiableTile = "🀔"d.convertToTiles[0];
	chiableTile.origin = new Ingame(PlayerWinds.south);
	assert(player.isChiable(chiableTile, metagame), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀔🀕"d.convertToTiles;
	chiableTile = "🀓"d.convertToTiles[0];
	chiableTile.origin = new Ingame(PlayerWinds.south);
	assert(player.isChiable(chiableTile, metagame), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto nonChiableTile = "🀔"d.convertToTiles[0];
	nonChiableTile.origin = new Ingame(PlayerWinds.south);
	assert(!player.isChiable(nonChiableTile, metagame), "The tile should not have been chiable");
}

unittest
{
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀁"d.convertToTiles;
	auto player2 = new Player(new TestEventHandler);
	auto metagame = new Metagame([player, player2]);
	metagame.currentPlayer = player2;
	auto nonChiableTile = "🀂"d.convertToTiles[0];
	nonChiableTile.origin = new Ingame(PlayerWinds.south);
	assert(!player.isChiable(nonChiableTile, metagame), "The tile should not have been chiable");
	player.game.closedHand.tiles = "🀄🀅"d.convertToTiles;
	nonChiableTile = "🀆"d.convertToTiles[0];
	nonChiableTile.origin = new Ingame(PlayerWinds.south);
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
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d.convertToTiles;
	auto player2 = new Player(new TestEventHandler);
	auto metagame = new Metagame([player, player2]);
	metagame.currentPlayer = player2;
	auto ponnableTile = "🀐"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(PlayerWinds.south);
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
	player.startGame(PlayerWinds.east);
	auto tiles = "🀓🀔"d.convertToTiles;
	player.game.closedHand.tiles = tiles;
	auto candidate = ChiCandidate(tiles[0], tiles[1]);
	auto chiableTile = "🀕"d.convertToTiles[0];
	chiableTile.origin = new Ingame(PlayerWinds.south);
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
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀕🀕"d.convertToTiles;
	auto ponnableTile = "🀕"d.convertToTiles[0];
	ponnableTile.origin = new Ingame(PlayerWinds.south);
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
	auto player = new Player(new TestEventHandler);
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀕🀕🀕"d.convertToTiles;
	auto kannableTile = "🀕"d.convertToTiles[0];
	kannableTile.origin = new Ingame(PlayerWinds.south);
	player.kan(kannableTile, wall);
	assert(player.game.closedHand.length == 1, "The tiles should have been removed from the hand and one tile drawn from the wall.");
	assert(player.game.openHand.amountOfPons == 1, "The open hand should have one pon.");
	assert(player.game.openHand.amountOfKans == 1, "The open hand should have one kan.");
	assert(player.game.openHand.sets.length == 1, "The open hand should have one set.");
	assertThrown!IllegalClaimException(player.kan(kannableTile, wall), "With no tiles in hand, an exception should be thrown.");
}

unittest
{
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	auto transaction = new Transaction(player, 5000);
	player.applyTransaction(transaction);
	assert(player.score == 35000, "The amount should have been added to the player's score.");
}

unittest
{
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	auto transaction = new Transaction(player, -5000);
	player.applyTransaction(transaction);
	assert(player.score == 25000, "The amount should have been subtracted from the player's score.");
}

unittest
{
	import core.exception;
	import std.exception;
	gameOpts = new DefaultGameOpts;
	auto player1 = new Player(new TestEventHandler);
	auto player2 = new Player(new TestEventHandler);
	auto transaction = new Transaction(player2, 5000);
	assertThrown!AssertError(player1.applyTransaction(transaction), "Applying someone else's transaction should not be allowed.");
}