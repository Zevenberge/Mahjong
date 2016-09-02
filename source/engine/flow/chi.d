module mahjong.engine.flow.chi;

import mahjong.domain;
import mahjong.engine.flow;

class ChiFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		_tile = tile;
		metagame = game;
	}

	override void advanceIfDone()
	{
		switchFlow(new TurnEndFlow(metagame));
	}

	private:
		Tile _tile;
}

class ChiEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}