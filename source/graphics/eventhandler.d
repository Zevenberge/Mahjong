module mahjong.graphics.eventhandler;

import std.experimental.logger;
import mahjong.engine.flow;
import mahjong.graphics.controllers;

class UiEventHandler : GameEventHandler
{
	override void handle(TurnEvent event) 
	{
		trace("UI: Handling turn event by switching controller");
		controller = new TurnController(controller.getWindow, event.metagame, event);
	}

}
