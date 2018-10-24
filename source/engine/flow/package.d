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

import std.algorithm : all;
import std.traits;
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

abstract class WaitForEveryPlayer(TEvent) : Flow
    if(canBeHandled!TEvent && canPlayerHandle!TEvent)
{
    this(Metagame metagame, INotificationService notificationService)
    {
        super(metagame, notificationService);
        notifyPlayers;
    }

    private void notifyPlayers()
    {
        foreach(player; _metagame.players)
        {
            auto event = createEvent();
            _events ~= event;
            player.eventHandler.handle(event);
        }
    }

    protected abstract TEvent createEvent();

    private TEvent[] _events;

    override void advanceIfDone()
    {
        if(isDone) advance();
    }

    private bool isDone()
    {
        return _events.all!(e => e.isHandled);
    }

    protected abstract void advance();
}

template canBeHandled(TEvent)
{
    enum canBeHandled = hasMember!(TEvent, "isHandled");
}

template canPlayerHandle(TEvent)
{
    enum canPlayerHandle = __traits(compiles, (GameEventHandler.init).handle(TEvent.init));
}