module mahjong.engine.flow.exhaustive;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;

class ExhaustiveDrawFlow : Flow
{
	this(Metagame game)
	{
		trace("Initialising exhaustive draw flow");
		super(game);
	}

	override void advanceIfDone()
	{
		
	}
}