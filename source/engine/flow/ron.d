module mahjong.engine.flow.ron;

import mahjong.domain;
import mahjong.engine.flow;

class RonFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		_tile = tile;
		metagame = game;
	}

	override void advanceIfDone()
	{
		switchFlow(new PonFlow(_tile, metagame));
	}
		
	private:
		Tile _tile;
}

class RonEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}