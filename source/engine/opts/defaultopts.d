module mahjong.engine.opts.defaultopts;

import mahjong.domain.enums.game;
import mahjong.engine.opts.opts;

class DefaultGameOpts : Opts
{
	int amountOfPlayers()
	{
		return 4;
	}
	int deadWallLength()
	{
		return 14;
	}
	GameMode gameMode()
	{
		return GameMode.Riichi;
	}
	int initialScore()
	{
		return 30_000;
	}
}