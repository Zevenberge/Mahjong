module mahjong.engine.flow.chi;

import mahjong.domain;
import mahjong.engine.flow;

class ChiFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		_tile = tile;
		_game = game;
	}

	override void advanceIfDone()
	{
		switchFlow(new TurnEndFlow(_game));
	}

	private:
		Tile _tile;
		Metagame _game;
}

class ChiEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}