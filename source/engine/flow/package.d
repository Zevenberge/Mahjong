module mahjong.engine.flow;

public import mahjong.engine.flow.abortive;
public import mahjong.engine.flow.chi;
public import mahjong.engine.flow.delegation;
public import mahjong.engine.flow.draw;
public import mahjong.engine.flow.exhaustive;
public import mahjong.engine.flow.mahjong;
public import mahjong.engine.flow.pon;
public import mahjong.engine.flow.ron;
public import mahjong.engine.flow.turn;
public import mahjong.engine.flow.turnend;

import mahjong.domain.metagame;

class Flow
{
	Metagame metagame;
	abstract void advanceIfDone();
}

Flow flow;

package void switchFlow(Flow newFlow)
{
	flow = newFlow;
}