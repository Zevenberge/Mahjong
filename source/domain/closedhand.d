module mahjong.domain.closedhand;

import std.algorithm.iteration;
import std.signals;
import dsfml.graphics;
import dsfml.system.vector2;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.mahjong;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.graphics;

class ClosedHand
{
	Tile[] tiles;
	
	void addTile(Tile tile)
	{
		tiles ~= tile;
		emit(tile);
	}
	
	mixin Signal!(Tile);
	
	void sortHand()
	{
		sort_hand(tiles);
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
