module mahjong.engine.flow.delegation;

import mahjong.engine.flow;

class Delegator
{
	abstract void handle(TurnEvent event);
}

version(unittest)
{
	class TestDelegator : Delegator
	{
		TurnEvent turnEvent;
		override void handle(TurnEvent event)
		{
			turnEvent = event;
		}
	}
}