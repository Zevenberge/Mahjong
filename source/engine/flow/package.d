module mahjong.engine.flow;

public import mahjong.engine.flow.draw;
public import mahjong.engine.flow.turn;

class Flow
{
	abstract void checkProgress();
}


Flow flow;

package void switchFlow(Flow newFlow)
{
	flow = newFlow;
}