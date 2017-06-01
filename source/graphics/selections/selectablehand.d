module mahjong.graphics.selections.selectablehand;

import std.conv;
import std.experimental.logger;
import std.range;
import dsfml.graphics;
import mahjong.domain.closedhand;
import mahjong.domain.tile;
import mahjong.engine.sort;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.selections.selectable;

class SelectableHand : Selectable!Tile
{
	this(ClosedHand hand)
	{
		_hand = hand;
	}
	
	private void newTileAdded()
	{
		auto newTile = _hand.lastTile;
		trace("Adding new tile to selectable hand.");
		_hand.tiles.sortHand;
		_hand.placeHand;
		opts = _hand.tiles;
		foreach(i, tile; opts)
		{
			if(tile.id == newTile.id)
			{
				changeOpt(i.to!int);
				break;
			}
		}
	}
	
	private ClosedHand _hand;
	private size_t _handSize;
	
	void draw(RenderTarget target)
	{
		if(_hand.length != _handSize) newTileAdded;
		if(opts.empty) return;
		opts = _hand.tiles;
		selectOpt;
		selection.draw(target);
	}
}