module mahjong.engine.flow.eventhandler;

import mahjong.domain.player;
import mahjong.engine.flow;

class GameEventHandler
{
	abstract void handle(TurnEvent event);
	abstract void handle(GameStartEvent event);
	abstract void handle(RoundStartEvent event);
	abstract void handle(ClaimEvent event);
	abstract void handle(KanStealEvent event);
	abstract void handle(MahjongEvent event);
    abstract void handle(AbortiveDrawEvent event);
	abstract void handle(GameEndEvent event);	
	abstract void handle(ExhaustiveDrawEvent event);
}

version(mahjong_test)
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

		ClaimEvent claimEvent;
		override void handle(ClaimEvent event)
		{
			trace("Handling claim event");
			claimEvent = event;
		}

		KanStealEvent kanStealEvent;
		override void handle(KanStealEvent event)
		{
			trace("Handling kan steal event");
			kanStealEvent = event;
		}

		MahjongEvent mahjongEvent;
		override void handle(MahjongEvent event)
		{
			trace("Handling mahjong event");
			mahjongEvent = event;
		}

		ExhaustiveDrawEvent exhaustiveDrawEvent;
		override void handle(ExhaustiveDrawEvent event)
		{
			trace("Handling exhaustive draw event");
			exhaustiveDrawEvent = event;
		}

        AbortiveDrawEvent abortiveDrawEvent;
        override void handle(AbortiveDrawEvent event)
        {
            trace("Handling abortive draw event");
            abortiveDrawEvent = event;
        }

		GameEndEvent gameEndEvent;
		override void handle(GameEndEvent event) 
		{
			trace("Handling game end event");
			gameEndEvent = event;
		}
	}
}