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

	import std.meta : AliasSeq;
	static foreach(Event; AliasSeq!(TurnEvent, ClaimEvent, KanStealEvent))
	{
		override void handle(Event event)
		{
			event.apply(_ai.decide(event));
		}
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