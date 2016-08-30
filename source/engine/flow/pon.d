module mahjong.engine.flow.pon;

import mahjong.domain;
import mahjong.engine.flow;

class PonFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		_tile = tile;
		_game = game;
	}

	override void advanceIfDone()
	{
		switchFlow(new ChiFlow(_tile, _game));
	}
	
	private:
		Tile _tile;
		Metagame _game;
}

class PonEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}