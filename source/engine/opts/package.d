module mahjong.engine.opts;

public import mahjong.engine.opts.bambooopts;
public import mahjong.engine.opts.defaultopts;
public import mahjong.engine.opts.eightplayeropts;

import mahjong.domain;
import mahjong.domain.enums;
import mahjong.engine.flow;

Opts gameOpts;

interface Opts
{
	int deadWallLength();
	int kanBuffer();
	int maxAmountOfKans();
	int amountOfPlayers();
	int initialScore();
	GameMode gameMode();
	Metagame createMetagame(GameEventHandler[] eventHandlers);
	PlayerWinds finalLeadingWind();
}