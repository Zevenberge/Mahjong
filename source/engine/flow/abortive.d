module mahjong.engine.flow.abortive;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class AbortiveDrawFlow : Flow
{
	this(Metagame game, INotificationService notificationService)
	{
		trace("Instantiating aborting draw flow");
		super(game, notificationService);
	}

	override void advanceIfDone()
	{
		
	}
}