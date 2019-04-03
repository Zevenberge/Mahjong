module mahjong.engine.opts;

public import mahjong.engine.opts.bambooopts;
public import mahjong.engine.opts.defaultopts;

import mahjong.domain;
import mahjong.domain.enums;
import mahjong.engine.flow;

interface Opts
{
	int deadWallLength() pure const;
    int riichiBuffer() pure const;
	int kanBuffer() pure const;
	int maxAmountOfKans() pure const;
	int amountOfPlayers() pure const;
	int initialScore() pure const;
    int riichiFare() pure const;
	GameMode gameMode() pure const;
	PlayerWinds finalLeadingWind() pure const;
    Wall createWall() pure const;
}