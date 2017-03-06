module mahjong.domain.player;

import std.experimental.logger;
import std.string;
import std.uuid;

import mahjong.domain.enums.game;
import mahjong.domain;
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

	bool isChiable(const Tile discard) pure const
	{
		return game.isChiable(discard);
	}

	bool isPonnable(const Tile discard) pure const
	{
		return game.isPonnable(discard);
	}

	bool isRonnable(const Tile discard) const
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
	auto chiableTile = "🀕"d.convertToTiles[0];
	assert(player.isChiable(chiableTile), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀓🀕"d.convertToTiles;
	chiableTile = "🀔"d.convertToTiles[0];
	assert(player.isChiable(chiableTile), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀔🀕"d.convertToTiles;
	chiableTile = "🀓"d.convertToTiles[0];
	assert(player.isChiable(chiableTile), "Expected the tile to be chiable");
	player.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
	auto nonChiableTile = "🀔"d.convertToTiles[0];
	assert(!player.isChiable(nonChiableTile), "The tile should not have been chiable");
}

unittest
{
	import mahjong.engine.creation;
	gameOpts = new DefaultGameOpts;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀀🀁"d.convertToTiles;
	auto nonChiableTile = "🀂"d.convertToTiles[0];
	assert(!player.isChiable(nonChiableTile), "The tile should not have been chiable");
	player.game.closedHand.tiles = "🀄🀅"d.convertToTiles;
	nonChiableTile = "🀆"d.convertToTiles[0];
	assert(!player.isChiable(nonChiableTile), "The tile should not have been chiable");
}