module mahjong.engine.flow.claim;

import mahjong.domain;
import mahjong.engine.flow;

class ClaimFlow : Flow
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

class ClaimEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}