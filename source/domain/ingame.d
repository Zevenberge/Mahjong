module mahjong.domain.ingame;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.uuid;
import mahjong.domain;
import mahjong.domain.enums.tile;
import mahjong.domain.exceptions;
import mahjong.engine.chi;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;
import mahjong.engine.sort;
import mahjong.share.range;

class Ingame
{ 
	this(int wind)
	{
		this.wind = wind;
		closedHand = new ClosedHand;
		openHand = new OpenHand;
		id = randomUUID;
	}

	const UUID id;
	// Ingame variables.
	const int wind; // What wind the player has. Initialise it with a value of -1 to allow easy assert(ingame.wind >= 0).
	ClosedHand closedHand; // The closed hand that can be changed. The discards are from here.
	OpenHand openHand; // The open pons/chis/kans 

	private Tile[] _discards;
	Tile[] discards() @property pure
	{
		return _discards;
	}

	version(unittest)
	{
		void setDiscards(Tile[] discs)
		{
			_discards = discs;
			foreach(tile; _discards)
			{
				tile.origin = this;
			}
		}
	}

	private Tile[] _claimedDiscards;
	private Tile[] allDiscards() @property pure
	{
		return discards ~_claimedDiscards;
	}

	void claim(Tile tile)
	{
		_discards.remove!((a, b) => a == b)(tile);
		_claimedDiscards ~= tile;
	}

	bool isNagashiMangan() @property
	{
		return openHand.sets.empty && allDiscards.all!(t => t.isHonour || t.isTerminal);
	}
	/*
	 Normal functions related to claiming tiles.
	 */
	private bool isOwn(const Tile tile) pure const
	{
		return tile.origin is null;
	}

	bool isChiable(const Tile discard) pure const
	{
		if(isOwn(discard)) return false;
		return closedHand.isChiable(discard);
	}

	void chi(Tile discard, ChiCandidate otherTiles)
	{
		if(!isChiable(discard) || !otherTiles.isChi(discard)) 
		{
			throw new IllegalClaimException(discard, "Chi not allowed");
		}
		discard.claim;
		auto chiTiles = closedHand.removeChiTiles(otherTiles) ~ discard;
		openHand.addChi(chiTiles);
		_lastTile = discard;
	}

	bool isPonnable(const Tile discard) pure
	{
		if(isOwn(discard)) return false;
		return closedHand.isPonnable(discard);
	}

	void pon(Tile discard)
	{
		if(!isPonnable(discard)) throw new IllegalClaimException(discard, "Pon not allowed");
		discard.claim;
		auto ponTiles = closedHand.removePonTiles(discard) ~ discard;
		openHand.addPon(ponTiles);
		_lastTile = discard;
	}

	bool isKannable(const Tile discard) pure
	{
		if(isOwn(discard)) return false;
		return closedHand.isKannable(discard);
	}

	void kan(Tile discard, Wall wall)
	{
		if(!isKannable(discard)) throw new IllegalClaimException(discard, "Kan not allowed");
		discard.claim;
		auto kanTiles = closedHand.removeKanTiles(discard) ~ discard;
		openHand.addKan(kanTiles);
		drawKanTile(wall);
	}

	bool isRonnable(const Tile discard) pure
	{
		return scanHandForMahjong(closedHand, openHand, discard).isMahjong
			&& !isFuriten ;
	}
	
	bool canDeclareClosedKan(const Tile tile)
	{
		return closedHand.canDeclareClosedKan(tile);
	}

	void declareClosedKan(const Tile tile, Wall wall)
	{
		auto kanTiles = closedHand.declareClosedKan(tile);
		openHand.addKan(kanTiles);
		drawKanTile(wall);
	}

	bool canPromoteToKan(Tile tile)
	{
		return openHand.canPromoteToKan(tile);
	}

	void promoteToKan(Tile tile, Wall wall)
	{
		closedHand.removeTile(tile);
		openHand.promoteToKan(tile);
		drawKanTile(wall);
	}

	private void drawKanTile(Wall wall)
	{
		closedHand.drawKanTile(wall);
		_lastTile = closedHand.lastTile;
	}

	/*
	 Functions related to the mahjong call.
	 */

	bool isTenpai()
	{ /*
		   Check whether a player sits tempai. Add one of each tile to the hand to see whether it will be a mahjong hand.
		   */
		for(int type = Types.min; type <= Types.max; ++type)
		{
			for(int value = Numbers.min; value <= Numbers.max; ++value)
			{
				auto tile = new Tile(type, value);
				if(.scanHandForMahjong(closedHand, openHand, tile).isMahjong)
				{
					return true;
				}

			}
		}
		return false;
	}

	bool isFuriten() @property pure
	{
		foreach(tile; allDiscards)
		{
			if(.scanHandForMahjong(closedHand, openHand, tile).isMahjong)
			{
				return true;
			}
		}
		return false;
	}

	bool canTsumo()
	{
		return  isOwn(_lastTile) && isMahjong;
	}

	bool isMahjong()
	{
		return scanHandForMahjong(closedHand, openHand).isMahjong;
	}

	private void discard(size_t discardedNr)
	{    
		takeOutTile(closedHand.tiles, _discards, discardedNr);
		auto discard = discards[$-1];
		discard.origin = this; // Sets the tile to be from the player who discarded it.
		discard.open;
	}

	void discard(Tile discardedTile)
	{
		ulong i = 0;
		foreach(tile; closedHand.tiles)
		{
			if(tile.isIdentical(discardedTile))
			{
				discard(i);
				return;
			}
			++i;
		}
		throw new TileNotFoundException(discardedTile);
	}

	private Tile _lastTile; 
	Tile lastTile() @property
	{
		return _lastTile;
	}

	void closeHand()
	{
		closedHand.closeHand;
	}

	void showHand()
	{
		closedHand.showHand;
	}
	
	void drawTile(Wall wall)
	{
		closedHand.drawTile(wall);
		_lastTile = closedHand.lastTile;
	}
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.opts;
	gameOpts = new DefaultGameOpts;
	auto ingame = new Ingame(1);
	ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	auto tile = ingame.closedHand.tiles.back;
	auto initialLength = ingame.closedHand.tiles.length;
	auto wall = new Wall;
	wall.setUp;
	wall.dice;
	ingame.declareClosedKan(tile, wall);
	assert(ingame.closedHand.tiles.length == initialLength - 3, "Four tiles should have been subtracted from the hand and one added");
	assert(ingame.openHand.amountOfKans == 1, "The open hand should have a kan");
}
unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.opts;
	gameOpts = new DefaultGameOpts;
	auto ingame = new Ingame(1);
	ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	auto tile = ingame.closedHand.tiles.back;
	tile.origin = new Ingame(2);
	ingame.pon(tile);
	auto initialLength = ingame.closedHand.tiles.length;
	auto wall = new Wall;
	wall.setUp;
	wall.dice;
	ingame.promoteToKan(ingame.closedHand.tiles.back, wall);
	assert(ingame.closedHand.tiles.length == initialLength, "One tile should have been subtracted from the hand and one added");
	assert(ingame.openHand.amountOfKans == 1, "The open hand should have a kan");
}
unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.opts;
	gameOpts = new DefaultGameOpts;
	auto ingame = new Ingame(1);
	ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
	auto ponTile = "🀟"d.convertToTiles[0];
	ponTile.origin = new Ingame(2);
	ingame.pon(ponTile);
	assert(!ingame.canTsumo, "After a claiming a tile, the player should no longer be able to tsumo.");
}
unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.opts;
	gameOpts = new DefaultGameOpts;
	auto ingame = new Ingame(1);
	ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
	auto chiTile = "🀡"d.convertToTiles[0];
	chiTile.origin = new Ingame(2);
	ingame.chi(chiTile, ChiCandidate(ingame.closedHand.tiles[6], ingame.closedHand.tiles[8]));
	assert(!ingame.canTsumo, "After a claiming a tile, the player should no longer be able to tsumo.");
}