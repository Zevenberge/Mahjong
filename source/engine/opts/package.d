module mahjong.engine.opts;

public import mahjong.engine.opts.bambooopts;
public import mahjong.engine.opts.defaultopts;
public import mahjong.engine.opts.eightplayeropts;

import mahjong.domain.enums.game;

Opts gameOpts;

interface Opts
{
	int deadWallLength();
	int kanBuffer();
	int maxAmountOfKans();
	int amountOfPlayers();
	int initialScore();
	GameMode gameMode();
}