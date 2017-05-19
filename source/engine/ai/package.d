module mahjong.engine.ai;

public import mahjong.engine.ai.eventhandler;

import std.experimental.logger;
import std.random;
import mahjong.engine.flow;

interface AI
{
	void playTurn(TurnEvent event);
	void claim(ClaimEvent event);
}

class SimpleAI : AI
{
	void playTurn(TurnEvent event)
	{
		trace("AI: playing turn.");

		if(event.player.isMahjong)
		{
			event.claimTsumo;
			return;
		}
		discardTile(event);
	}

	private void discardTile(TurnEvent event)
	{
		auto hand = event.player.game.closedHand.tiles;
		auto discard = uniform(0, hand.length);
		event.discard(hand[discard]);
	}

	void claim(ClaimEvent event)
	{
		// TODO
		//if(event.player.isRonnable(event.tile)) event.handle(new RonRequest);
		//if(event.player.isPonnable(event.tile)) event.handle(new PonRequest);
		event.handle(new NoRequest);
	}
}
