module mahjong.domain.exceptions.tilenotfound;

import std.string;
import mahjong.domain.tile;

class TileNotFoundException : Exception
{
	this(Tile expectedTile)
	{
		super("Could not find the tile with type %s and value %s and id %s"
			.format(expectedTile.type, expectedTile.value, expectedTile.id));
	}
}

