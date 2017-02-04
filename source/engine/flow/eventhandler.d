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
	import std.experimental.logger;

	class TestEventHandler : GameEventHandler
	{
		TurnEvent turnEvent;
		override void handle(TurnEvent event)
		{
			trace("Handling turn event");
			turnEvent = event;
		}

		GameStartEvent gameStartEvent;
		override void handle(GameStartEvent event)
		{
			trace("Handling game start event");
			gameStartEvent = event;
		}

		RoundStartEvent roundStartEvent;
		override void handle(RoundStartEvent event) 
		{
			trace("Handling round start event");
			roundStartEvent = event;
		}

	}
}