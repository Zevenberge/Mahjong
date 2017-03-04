module mahjong.engine.flow.mahjong;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;

class MahjongFlow : Flow
{
	this(Metagame game)
	{
		trace("Constructing mahjong flow");
		super(game);
	}

	override void advanceIfDone()
	{
		
	}
}