module mahjong.engine.flow.exhaustive;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class ExhaustiveDrawFlow : Flow
{
	this(Metagame game, INotificationService notificationService)
	{
		trace("Initialising exhaustive draw flow");
		super(game, notificationService);
	}

	override void advanceIfDone()
	{
		
	}
}