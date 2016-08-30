module mahjong.engine.flow;

public import mahjong.engine.flow.delegation;
public import mahjong.engine.flow.draw;
public import mahjong.engine.flow.ron;
public import mahjong.engine.flow.turn;

class Flow
{
	abstract void advanceIfDone();
}


Flow flow;

package void switchFlow(Flow newFlow)
{
	flow = newFlow;
}