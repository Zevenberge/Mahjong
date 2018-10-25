module mahjong.engine.flow.exhaustive;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class ExhaustiveDrawFlow : WaitForEveryPlayer!ExhaustiveDrawEvent
{
    this(Metagame game, INotificationService notificationService)
    {
        trace("Initialising exhaustive draw flow");
        notificationService.notify(Notification.ExhaustiveDraw);
        super(game, notificationService);
    }

    protected override ExhaustiveDrawEvent createEvent()
    {
        return new ExhaustiveDrawEvent(_metagame);
    }

    protected override void advance()
    {
        _metagame.finishRound;
        mixin(switchToNextRoundOrGameOver);
    }
}

class ExhaustiveDrawEvent
{
    this(const Metagame metagame)
    {
        this.metagame = metagame;
    }

    const Metagame metagame;

    private bool _isHandled;
	bool isHandled() @property
	{
		return _isHandled;
	}

	void handle()
	{
		_isHandled = true;
	}
}