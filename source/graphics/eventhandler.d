﻿module mahjong.graphics.eventhandler;

import std.experimental.logger;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.drawing.ingame;

class UiEventHandler : GameEventHandler
{
	override void handle(TurnEvent event) 
	{
		info("UI: Handling turn event by switching controller");
		trySwitchController(new TurnController(controller.getWindow, event.metagame, event));
	}
	
	override void handle(GameStartEvent event)
	{
		info("UI: Handling game start event by creating an idle controller");
		trySwitchController(new IdleController(controller.getWindow, event.metagame));
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
			trySwitchController(new ClaimController(controller.getWindow, event.metagame, controller, factory));
		}
		else
		{
			event.handle(new NoRequest);
		}
	}

	override void handle(MahjongEvent event)
	{
		trySwitchController(new ResultController(controller.getWindow, event.metagame, event));
	}

	override void handle(GameEndEvent event) 
	{
		trySwitchController(new GameEndController(controller.getWindow, event.metagame, event));
	}

}
