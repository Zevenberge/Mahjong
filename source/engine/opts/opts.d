module mahjong.engine.opts.opts;

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