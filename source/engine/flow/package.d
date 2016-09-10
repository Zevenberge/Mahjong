module mahjong.engine.flow;

public 
{
	import mahjong.engine.flow.abortive;
	import mahjong.engine.flow.chi;
	import mahjong.engine.flow.eventhandler;
	import mahjong.engine.flow.draw;
	import mahjong.engine.flow.exhaustive;
	import mahjong.engine.flow.gamestart;
	import mahjong.engine.flow.mahjong;
	import mahjong.engine.flow.pon;
	import mahjong.engine.flow.ron;
	import mahjong.engine.flow.roundstart;
	import mahjong.engine.flow.turn;
	import mahjong.engine.flow.turnend;
}

import mahjong.domain.metagame;

class Flow
{
	Metagame metagame;
	abstract void advanceIfDone();
}

Flow flow;

void switchFlow(Flow newFlow)
{
	flow = newFlow;
}