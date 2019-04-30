module mahjong.ai.eventhandler;

import mahjong.ai;
import mahjong.engine.flow;

class AiEventHandler : GameEventHandler
{
	this(AI ai)
	{
		_ai = ai;
	}

	private AI _ai;

	override void handle(TurnEvent event)
	{
		_ai.playTurn(event);
	}
	override void handle(GameStartEvent event)
	{
		event.isReady = true;
	}
	override void handle(RoundStartEvent event)
	{
		event.isReady = true;
	}
	override void handle(ClaimEvent event) 
	{
		_ai.claim(event);
	}
	override void handle(KanStealEvent event)
	{
		_ai.steal(event);
	}
	override void handle(MahjongEvent event)
	{
		event.handle;
	}
	override void handle(ExhaustiveDrawEvent event)
	{
		event.handle;
	}
    override void handle(AbortiveDrawEvent event)
    {
        event.handle;
    }
	override void handle(GameEndEvent event) 
	{
		event.handle;
	}
}