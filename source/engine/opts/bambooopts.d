module mahjong.engine.opts.bambooopts;

import mahjong.domain.enums.game;
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
}