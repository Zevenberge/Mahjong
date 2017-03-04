module mahjong.engine.flow.abortive;

import std.experimental.logger;
import mahjong.domain.metagame;

import mahjong.engine.flow;

class AbortiveDrawFlow : Flow
{
	this(Metagame game)
	{
		trace("Instantiating aborting draw flow");
		super(game);
	}

	override void advanceIfDone()
	{
		
	}
}