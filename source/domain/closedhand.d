module mahjong.domain.closedhand;

import std.algorithm.iteration;
import std.array;
import std.signals;
import mahjong.domain;
import mahjong.engine.mahjong;
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
		tiles.remove!((a,b)=> a.id == b.id)(tile);
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

	void drawTile(ref Wall wall)
	{
		addTile(wall.drawTile);
	}
	
	Tile getLastTile()
	{
		return tiles[$-1];
	}

	bool isPonnable(const Tile discard)
	{
		return tiles.filter!(tile => tile.hasEqualValue(discard)).array.length >= 2;
	}

	bool isKannable(const Tile discard)
	{
		return tiles.filter!(tile => tile.hasEqualValue(discard)).array.length >= 3;
	}
}
