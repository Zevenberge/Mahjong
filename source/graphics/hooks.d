module mahjong.graphics.hooks;

import std.experimental.logger;
import mahjong.engine.flow.hooks;
import mahjong.graphics.drawing.player;

class GraphicalFlowHooks : FlowHooks
{
	void onRoundStarted()	
	{
		info("Handling start of round in the graphical flow");
	//	updateWindsOfExistingPlayers;
	}
}

