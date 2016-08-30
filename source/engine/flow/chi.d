module mahjong.engine.flow.chi;

import mahjong.domain;

class ChiFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		
	}

	override void advanceIfDone()
	{
		
	}
}

class ChiEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}