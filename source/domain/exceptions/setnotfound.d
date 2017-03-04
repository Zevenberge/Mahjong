module mahjong.domain.exceptions.setnotfound;

import std.string;
import mahjong.domain.tile;

class SetNotFoundException : Exception
{
	this(Tile expectedTile)
	{
		super("Could not find a set of tiles with type %s and value %s and id %s"
			.format(expectedTile.type, expectedTile.value, expectedTile.id));
	}
}
