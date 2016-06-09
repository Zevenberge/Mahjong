module mahjong.engine.opts.defaultopts;

import mahjong.domain.enums.game;
import mahjong.engine.opts.opts;

class DefaultOpts : Opts
{
	int amountOfPlayers()
	{
		return 4;
	}
	int initialScore()
	{
		return 30_000;
	}
	GameMode gameMode()
	{
		return GameMode.Riichi;
	}
}