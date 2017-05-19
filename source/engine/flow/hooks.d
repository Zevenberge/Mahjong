module mahjong.engine.flow.hooks;

FlowHooks hooks;

interface FlowHooks
{
	void onRoundStarted();
}

class EmptyFlowHooks : FlowHooks
{
	void onRoundStarted()
	{

	}
}

static this()
{
	hooks = new EmptyFlowHooks;
}