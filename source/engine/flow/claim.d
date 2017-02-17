module mahjong.engine.flow.claim;

import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;

class ClaimFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		trace("Constructing claim flow");
		_tile = tile;
		metagame = game;
	}

	override void advanceIfDone()
	{
		switchFlow(new TurnEndFlow(metagame));
	}
		
	private:
		const Tile _tile;
}

class ClaimEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	const Tile tile;
}