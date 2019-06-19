module mahjong.domain.opts;

public import mahjong.domain.opts.bambooopts;
public import mahjong.domain.opts.defaultopts;

import mahjong.domain;
import mahjong.domain.enums;

interface Opts
{
	Wall createWall() pure const;
	@nogc nothrow:
	int deadWallLength() pure const;
    int riichiBuffer() pure const;
	int kanBuffer() pure const;
	int maxAmountOfKans() pure const;
	int amountOfPlayers() pure const;
	int initialScore() pure const;
    int riichiFare() pure const;
	GameMode gameMode() pure const;
	PlayerWinds finalLeadingWind() pure const;
}