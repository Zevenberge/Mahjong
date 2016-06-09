module mahjong.engine.opts.bambooopts;

import mahjong.domain.enums.game;
import mahjong.engine.opts.defaultopts;

class BambooOpts : DefaultOpts
{
	override int amountOfPlayers()
	{
		return 2;
	}
	override GameMode gameMode()
	{
		return GameMode.Bamboo;
	}
}