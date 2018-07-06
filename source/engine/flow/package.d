module mahjong.engine.flow;

public 
{
	import mahjong.engine.flow.abortive;
	import mahjong.engine.flow.claim;
	import mahjong.engine.flow.eventhandler;
	import mahjong.engine.flow.draw;
	import mahjong.engine.flow.exhaustive;
	import mahjong.engine.flow.gameend;
	import mahjong.engine.flow.gamestart;
	import mahjong.engine.flow.mahjong;
	import mahjong.engine.flow.roundstart;
	import mahjong.engine.flow.turn;
	import mahjong.engine.flow.turnend;
}

import mahjong.domain.metagame;
import mahjong.engine.notifications;

class Flow
{
	this(Metagame game, INotificationService notificationService)
	{
		_metagame = game;
		_notificationService = notificationService;
	}

	protected INotificationService _notificationService;
	protected Metagame _metagame;
	final const(Metagame) metagame() @property pure const
	{
		return _metagame;
	}

	abstract void advanceIfDone();
}

Flow flow;

void switchFlow(Flow newFlow)
{
	flow = newFlow;
}