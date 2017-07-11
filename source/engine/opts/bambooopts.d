module mahjong.engine.opts.bambooopts;

import mahjong.domain;
import mahjong.domain.enums;
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
	override PlayerWinds finalLeadingWind()
	{
		//return PlayerWinds.east;
		return PlayerWinds.north;
	}
}