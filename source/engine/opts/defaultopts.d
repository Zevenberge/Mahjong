module mahjong.engine.opts.defaultopts;

import std.algorithm.iteration;
import std.array;
import mahjong.domain;
import mahjong.domain.enums;
import mahjong.engine.flow;
import mahjong.engine.opts;

class DefaultGameOpts : Opts
{
	int amountOfPlayers() pure const
	{
		return 4;
	}
	int deadWallLength() pure const
	{
		return 14;
	}
    int riichiBuffer() pure const
    {
        return 4;
    }
	int kanBuffer() pure const
	{
		return 0;
	}
	int maxAmountOfKans() pure const
	{
		return 4;
	}
	GameMode gameMode() pure const
	{
		return GameMode.Riichi;
	}
	int initialScore() pure const
	{
		return 30_000;
	}
    int riichiFare() pure const
    {
        return 1_000;
    }	
	PlayerWinds finalLeadingWind() pure const
	{
		return PlayerWinds.south;
	}
}