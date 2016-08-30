module mahjong.engine.flow.delegation;

class Delegator
{
	abstract handle(TurnEvent event);
}

version(unittest)
{
	class TestDelegator : Delegator
	{
		import mahjong.engine.flow;
		TurnEvent turnEvent;
		override handle(TurnEvent event)
		{
			turnEvent = event;
		}
	}
}