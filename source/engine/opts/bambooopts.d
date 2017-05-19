module mahjong.engine.opts.bambooopts;

import mahjong.domain;
import mahjong.domain.enums.game;
import mahjong.engine.flow;
import mahjong.engine.opts;

class BambooOpts : DefaultGameOpts
{
	override int amountOfPlayers()
	{
		return 2;
	}
	override int deadWallLength()
	{
		return 0;
	}
	override GameMode gameMode()
	{
		return GameMode.Bamboo;
	}
	override Metagame createMetagame(GameEventHandler[] eventHandlers) 
	{
		return new BambooMetagame(createPlayers(eventHandlers));
	}

}