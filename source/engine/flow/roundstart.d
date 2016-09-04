module mahjong.engine.flow.roundstart;

import mahjong.domain;
import mahjong.engine.flow;

class RoundStartFlow : Flow
{
	this(Metagame metagame)
	{
		this.metagame = metagame;
		foreach(player; metagame.players)
		{
			auto event = new RoundStartEvent(metagame);
			_events ~= event;
			player.eventHandler.handle(event);
		}
	}

	private RoundStartEvent[] _events;

	override void advanceIfDone() 
	{

	}

}

class RoundStartEvent
{
	this(Metagame metagame)
	{
		this.metagame = metagame;
	}

	Metagame metagame;
	bool isReady;
}