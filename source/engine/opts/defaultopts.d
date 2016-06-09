module mahjong.engine.opts.defaultopts;

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
}