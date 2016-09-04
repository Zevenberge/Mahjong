module mahjong.engine.ai.eventhandler;

import mahjong.engine.ai;
import mahjong.engine.flow;

class AiEventHandler : GameEventHandler
{
	override void handle(TurnEvent event)
	{
		playTurn(event);
	}
	override void handle(GameStartEvent event)
	{
		event.isReady = true;
	}
}