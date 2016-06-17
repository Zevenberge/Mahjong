module mahjong.domain.hand;

import std.signals;
import mahjong.domain.tile;

class Hand 
{
	Tile[] tiles;
	
	void addTile(Tile tile)
	{
		tiles ~= tile;
		emit(tile);
	}
	
	mixin Signal!(Tile);
	
}
