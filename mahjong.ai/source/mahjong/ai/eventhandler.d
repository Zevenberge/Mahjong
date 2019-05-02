module mahjong.ai.eventhandler;

import mahjong.ai;
import mahjong.engine.flow;
import mahjong.engine.flow.traits;

class AiEventHandler : GameEventHandler
{
	this(AI ai)
	{
		_ai = ai;
	}

	private AI _ai;

	override void handle(TurnEvent event)
	{
		_ai.playTurn(event);
	}
	override void handle(ClaimEvent event) 
	{
		_ai.claim(event);
	}
	override void handle(KanStealEvent event)
	{
		_ai.steal(event);
	}
	mixin HandleSimpleEvents!();	
}

@("The AI event handler should not be abstract")
unittest
{
	import std.traits;
	import fluent.asserts;
	isAbstractClass!AiEventHandler.should.equal(false);
}