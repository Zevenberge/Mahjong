module mahjong.domain.closedhand;

import std.algorithm.iteration;
import dsfml.graphics;
import dsfml.system.vector2;
import mahjong.domain.hand;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.mahjong;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.graphics;

class ClosedHand : Hand
{
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
		tiles ~= wall.drawTile;
		selectDrawnTile();
	}
	
	Tile getLastTile()
	{
		return tiles[$-1];
	}

	void drawOpt(RenderTarget window)
	{ // TODO: responsibility of controller.
		selectOpt();
		window.draw(selection.visual);
	}

	void selectDrawnTile()
	{
		auto drawnTile = tiles[$-1];
		sort_hand(tiles);
		for(int i = 0; i < tiles.length; ++i)
		{
			if(is_identical(tiles[i], drawnTile))
			{
				changeOpt(i);
				break;
			}
		}
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
