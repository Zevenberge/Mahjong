module mahjong.engine.flow.eventhandler;

import mahjong.engine.flow;

class GameEventHandler
{
	abstract void handle(TurnEvent event);
	abstract void handle(GameStartEvent event);
	abstract void handle(RoundStartEvent event);
}

version(unittest)
{
	class TestEventHandler : GameEventHandler
	{
		TurnEvent turnEvent;
		override void handle(TurnEvent event)
		{
			turnEvent = event;
		}

		GameStartEvent gameStartEvent;
		override void handle(GameStartEvent event)
		{
			gameStartEvent = event;
		}

		RoundStartEvent roundStartEvent;
		override void handle(RoundStartEvent event) 
		{
			roundStartEvent = event;
		}

	}
}