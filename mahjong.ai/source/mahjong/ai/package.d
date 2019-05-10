module mahjong.ai;

public import mahjong.ai.decision;
public import mahjong.ai.eventhandler;

import std.experimental.logger;
import std.random;
import mahjong.engine.flow;

interface AI
{
	const(TurnDecision) decide(const TurnEvent);
	const(ClaimDecision) decide(const ClaimEvent);
	const(KanStealDecision) decide(const KanStealEvent);
}

class SimpleAI : AI
{
	override const(TurnDecision) decide(const TurnEvent event)
	{
		import mahjong.util.log : logAspect;
		mixin(logAspect!(LogLevel.info, "AI Turn"));
		import std.random : randomSample;
		if(event.player.isMahjong)
		{
			return TurnDecision(event.player, TurnDecision.Action.tsumo, null);
		}
		auto tile = event.player.closedHand.tiles.randomSample(1).front;
		return TurnDecision(event.player,TurnDecision.Action.discard, tile);
	}

	override const(KanStealDecision) decide(const KanStealEvent event)
	{
		return KanStealDecision(event.player, false);
	}

	override const(ClaimDecision) decide(const ClaimEvent event)
	{
		return ClaimDecision(event.player, Request.None);
	}
}

