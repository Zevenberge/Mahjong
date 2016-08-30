module mahjong.engine.flow.pon;

import mahjong.domain;

class PonFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		
	}

	override void advanceIfDone()
	{
		
	}
}

class PonEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}