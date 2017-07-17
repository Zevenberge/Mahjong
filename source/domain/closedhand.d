module mahjong.domain.closedhand;

import std.algorithm;
import std.array;
import mahjong.domain;
import mahjong.domain.exceptions;
import mahjong.engine.chi;
import mahjong.engine.sort;
import mahjong.share.range;

class ClosedHand
{
	Tile[] tiles;

	size_t length() @property
	{
		return tiles.length;
	}

	Tile removeTile(const Tile tile)
	{
		return tiles.remove!((a,b) => a == b)(tile);
	}
	
	void sortHand()
	{
		.sortHand(tiles);
	}

	void closeHand()
	{
		tiles.each!(t => t.close);
	}

	void showHand()
	{
		tiles.each!(t => t.open);
	}

	void drawTile(Wall wall)
	{
		addTile(wall.drawTile);
	}

	void drawKanTile(Wall wall)
	{
		addTile(wall.drawKanTile);
	}

	private void addTile(Tile tile)
	{
		tiles ~= tile;
	}

	Tile lastTile() @property
	{
		return tiles[$-1];
	}

	bool isChiable(const Tile discard) pure const
	{
		return !determineChiCandidates(tiles, discard).empty;
	}

	Tile[] removeChiTiles(ChiCandidate otherChiTiles)
	{
		auto chiTiles = tiles.filter!(t => 
			t.id == otherChiTiles.first.id || 
			t.id == otherChiTiles.second.id).array;
		chiTiles.each!(t => removeTile(t));
		return chiTiles;
	}

	bool isPonnable(const Tile discard) pure
	{
		return tilesWithEqualValue(discard).length >= 2;
	}

	Tile[] removePonTiles(const Tile discard)
	{
		return removeTilesWithIdenticalValue!2(discard);
	}

	bool isKannable(const Tile discard) pure
	{
		return tilesWithEqualValue(discard).length >= 3;
	}

	Tile[] removeKanTiles(const Tile discard)
	{
		return removeTilesWithIdenticalValue!3(discard);
	}

	bool canDeclareClosedKan(const Tile tile) pure const
	{
		return tiles.count!(t => tile.hasEqualValue(t)) >= 4;
	}

	Tile[] declareClosedKan(const Tile tile)
	{
		if(!canDeclareClosedKan(tile)) throw new IllegalClaimException(tile, "Cannot declare a closed kan");
		return removeTilesWithIdenticalValue!4(tile);
	}

	private Tile[] tilesWithEqualValue(const Tile other) pure
	{
		return tiles.filter!(tile => tile.hasEqualValue(other)).array;
	}

	private Tile[] removeTilesWithIdenticalValue(int amount)(const Tile other)
	{
		auto removedTiles = tilesWithEqualValue(other)[0 .. amount];
		tiles = tiles.without!((a,b) => a == b)(removedTiles);
		return removedTiles;
	}
}

unittest
{
	import mahjong.engine.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	assert(!closedHand.canDeclareClosedKan(closedHand.tiles.front), 
		"As there are only three copies of the tile in the hand, no closed kan can be claimed");
	assert(closedHand.canDeclareClosedKan(closedHand.tiles.back), 
		"As there are four copies of the tile, a closed kan can be declared.");
}

unittest
{
	import mahjong.engine.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	auto initialLength = closedHand.tiles.length;
	auto tile = closedHand.tiles.back;
	auto kanTiles = closedHand.declareClosedKan(tile);
	assert(kanTiles.length == 4, "Four tiles should be returned when a closed kan is declared");
	assert(kanTiles.all!(kt => tile.hasEqualValue(kt)), "All returned tiles should have the same value as the requested tile");
	assert(closedHand.tiles.length == initialLength - 4, "Four tiles should have been subtracted from the hand");
	assert(!closedHand.tiles.any!(t => tile.hasEqualValue(t)), "All tiles with the requested value should have been removed");
}
unittest
{
	import std.exception;
	import mahjong.engine.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	assertThrown!IllegalClaimException(closedHand.declareClosedKan(closedHand.tiles.front), 
		"Trying to declare a closed kan when it is not allowed should be rewarded with an exception.");
}