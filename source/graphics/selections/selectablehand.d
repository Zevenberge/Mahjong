module mahjong.graphics.selections.selectablehand;

import std.conv;
import dsfml.graphics;
import mahjong.domain.hand;
import mahjong.domain.tile;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.selections.selectable;

class SelectableHand : Selectable!Tile
{
	this(Hand hand)
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
				changeOpts(i.to!int);
				break;
			}
		}
	}
	
	private Hand _hand;
	
	void draw(RenderTarget target)
	{
		selection.draw(target);
		_hand.draw(target);
	}
}