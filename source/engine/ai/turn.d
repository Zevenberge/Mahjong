module mahjong.engine.ai.turn;

import std.experimental.logger;
import std.random;
import mahjong.engine.ai;
import mahjong.engine.flow;

void playTurn(TurnEvent event)
{
	trace("AI: playing turn.");
	if(isTsumo(event))
	{
		event.claimTsumo;
		return;
	}
	discardTile(event);
}

private bool isTsumo(TurnEvent event)
{
	// If we can claim a tsumo, we do it.
	return event.player.isMahjong;
}

private void discardTile(TurnEvent event)
{
	auto hand = event.player.game.closedHand.tiles;
	auto discard = uniform(0, hand.length);
	event.discard(hand[discard]);
}