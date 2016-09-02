module mahjong.engine.flow.pon;

import mahjong.domain;
import mahjong.engine.flow;

class PonFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		_tile = tile;
		metagame = game;
	}

	override void advanceIfDone()
	{
		switchFlow(new ChiFlow(_tile, metagame));
	}
	
	private:
		Tile _tile;
}

class PonEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}