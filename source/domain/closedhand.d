module mahjong.domain.closedhand;

import std.algorithm.iteration;
import std.array;
import std.signals;
import mahjong.domain;
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
	
	void addTile(Tile tile)
	{
		tiles ~= tile;
		emit(tile);
	}

	void removeTile(Tile tile)
	{
		tiles.remove!((a,b) => a == b)(tile);
	}
	
	mixin Signal!(Tile);
	
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

	Tile getLastTile()
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

	private Tile[] tilesWithEqualValue(const Tile other) pure
	{
		return tiles.filter!(tile => tile.hasEqualValue(other)).array;
	}

	private Tile[] removeTilesWithIdenticalValue(int amount)(const Tile other)
	{
		auto removedTiles = tilesWithEqualValue(other)[0 .. amount];
		removedTiles.each!(t => removeTile(t));
		return removedTiles;
	}
}
