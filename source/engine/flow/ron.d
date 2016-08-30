module mahjong.engine.flow.ron;

import mahjong.domain;

class RonFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		
	}

	override void advanceIfDone()
	{
		
	}
}

class RonEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}