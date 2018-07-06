module mahjong.graphics.eventhandler;

import std.experimental.logger;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.drawing.ingame;

class UiEventHandler : GameEventHandler
{
	override void handle(TurnEvent event) 
	{
		info("UI: Handling turn event by switching controller");
		Controller.instance.substitute(new TurnController(Controller.instance.getWindow, event.metagame, event));
	}
	
	override void handle(GameStartEvent event)
	{
		info("UI: Handling game start event by creating an idle controller");
		Controller.instance.substitute(new IdleController(Controller.instance.getWindow, event.metagame));
		event.isReady = true;
	}

	override void handle(RoundStartEvent event)
	{
		clearIngameCache;
		event.isReady = true;
	}

	override void handle(ClaimEvent event) 
	{
		auto factory = new ClaimOptionFactory(event.player, event.tile, event.metagame, event);
		if(factory.areThereClaimOptions)
		{
			info("UI: Handling turn event by switching to the claim controller");
			Controller.instance.substitute(new ClaimController(Controller.instance.getWindow, event.metagame, Controller.instance, factory));
		}
		else
		{
			event.handle(new NoRequest);
		}
	}

	override void handle(MahjongEvent event)
	{
		Controller.instance.substitute(new ResultController(Controller.instance.getWindow, event.metagame, event));
	}

	override void handle(GameEndEvent event) 
	{
		Controller.instance.substitute(new GameEndController(Controller.instance.getWindow, event.metagame, event));
	}

}
