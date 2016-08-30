module mahjong.engine.ai.delegation;

import mahjong.engine.ai;
import mahjong.engine.flow;

class AiDelegator : Delegator
{
	override handle(TurnEvent event)
	{
		playTurn(event);
	}
}