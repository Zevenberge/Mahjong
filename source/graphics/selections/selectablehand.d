module mahjong.graphics.selections.selectablehand;

import std.conv;
import std.range;
import dsfml.graphics;
import mahjong.domain.closedhand;
import mahjong.domain.tile;
import mahjong.graphics.selections.selectable;

class SelectableHand : Selectable!Tile
{
	this(ClosedHand hand)
	{
		_hand = hand;
		_hand.connect(&newTileAdded);
	}
	
	private void newTileAdded(Tile newTile)
	{
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
	
	void draw(RenderTarget target)
	{
		if(opts.empty) return;
		selection.draw(target);
	}
}