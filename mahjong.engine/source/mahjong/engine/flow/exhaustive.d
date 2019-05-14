module mahjong.engine.flow.exhaustive;

import std.experimental.logger;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class ExhaustiveDrawFlow : WaitForEveryPlayer!ExhaustiveDrawEvent
{
    this(Metagame game, INotificationService notificationService, Engine engine)
    {
        trace("Initialising exhaustive draw flow");
        game.exhaustiveDraw;
        notificationService.notify(Notification.ExhaustiveDraw);
        super(game, notificationService, engine);
    }

    protected override ExhaustiveDrawEvent createEvent()
    {
        return new ExhaustiveDrawEvent(_metagame);
    }

    protected override void advance(Engine engine)
    {
        _metagame.finishRound;
        mixin(switchToNextRoundOrGameOver);
    }
}

final class ExhaustiveDrawEvent
{
	import mahjong.engine.flow.traits : SimpleEvent;

    this(const Metagame metagame)
    {
        this.metagame = metagame;
    }

    const Metagame metagame;

	mixin SimpleEvent!();
 }

@("An exhaustive draw event is simple")
unittest
{
    import fluent.asserts;
    import mahjong.engine.flow.traits;
    isSimpleEvent!ExhaustiveDrawEvent.should.equal(true);
}