module mahjong.domain.closedhand;

import std.algorithm.iteration;
import std.signals;
import mahjong.domain.tile;
import mahjong.domain.wall;
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

	void open()
	{
		foreach(tile; tiles)
		{
			tile.open;
		}
	}
	void close()
	{
		foreach(tile; tiles)
		{
			tile.close;
		}
	}
}
