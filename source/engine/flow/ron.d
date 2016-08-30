module mahjong.engine.flow.ron;

import mahjong.domain;
import mahjong.engine.flow;

class RonFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		_tile = tile;
		_game = game;
	}

	override void advanceIfDone()
	{
		switchFlow(new PonFlow(_tile, _game));
	}
		
	private:
		Tile _tile;
		Metagame _game;
}

class RonEvent
{
	this(Tile tile, Player player)
	{
		this.tile = tile;
	}
	
	Tile tile;
}