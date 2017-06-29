module mahjong.engine.opts.defaultopts;

import std.algorithm.iteration;
import std.array;
import mahjong.domain;
import mahjong.domain.enums;
import mahjong.engine.flow;
import mahjong.engine.opts;

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
	int kanBuffer()
	{
		return 0;
	}
	int maxAmountOfKans()
	{
		return 4;
	}
	GameMode gameMode()
	{
		return GameMode.Riichi;
	}
	int initialScore()
	{
		return 30_000;
	}
	Metagame createMetagame(GameEventHandler[] delegators)
	{
		return new Metagame(createPlayers(delegators));
	}
	protected Player[] createPlayers(GameEventHandler[] eventHandlers)
	{
		return eventHandlers.map!(d => d.createPlayer).array;
	}
	PlayerWinds finalLeadingWind()
	{
		return PlayerWinds.north;
	}
}