module mahjong.ai;

public import mahjong.ai.eventhandler;

import std.experimental.logger;
import std.random;
import mahjong.engine.flow;

interface AI
{
	void playTurn(TurnEvent event);
	void claim(ClaimEvent event);
	void steal(KanStealEvent event);
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
		event.handle(new NoRequest);
	}

	void steal(KanStealEvent event)
	{
		event.pass;
	}
}
