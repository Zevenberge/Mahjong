module mahjong.graphics.eventhandler;

import std.experimental.logger;
import mahjong.engine.flow;
import mahjong.graphics.controllers;

class UiEventHandler : GameEventHandler
{
	override void handle(TurnEvent event) 
	{
		info("UI: Handling turn event by switching controller");
		controller = new TurnController(controller.getWindow, event.metagame, event);
	}
	
	override void handle(GameStartEvent event)
	{
		info("UI: Handling game start event by creating an idle controller");
		controller = new IdleController(controller.getWindow, event.metagame);
		event.isReady = true;
	}

	override void handle(RoundStartEvent event)
	{
		event.isReady = true;
	}

	override void handle(ClaimEvent event) 
	{
		auto factory = new ClaimOptionFactory(event.player, event.tile, event.metagame, event);
		if(factory.areThereClaimOptions)
		{
			info("UI: Handling turn event by switching to the claim controller");
			controller = new ClaimController(controller.getWindow, event.metagame, controller, factory);
		}
		else
		{
			event.handle(new NoRequest);
		}
	}

	override void handle(MahjongEvent event)
	{
		// TODO
	}
}
