module mahjong.engine.flow.turnend;

import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class TurnEndFlow : Flow
{
	this(Metagame game, INotificationService notificationService)
	{
		super(game, notificationService);
	}
	
	override void advanceIfDone()
	{
		if(_metagame.isAbortiveDraw)
		{
			info("Abortive draw reached.");
			switchFlow(new AbortiveDrawFlow(_metagame, _notificationService));
		}
		else if(_metagame.isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
            if(_metagame.isAnyPlayerNagashiMangan)
            {
                switchFlow(new MahjongFlow(_metagame, _notificationService));
            }
            else
            {
                switchFlow(new ExhaustiveDrawFlow(_metagame, _notificationService));
            }
		}
		else
		{
			trace("Advancing to the next turn.");
			_metagame.advanceTurn;
			switchFlow(new DrawFlow(_metagame.currentPlayer, _metagame, _metagame.wall, _notificationService));
		}
	}
}

version(unittest)
{
    import std.algorithm;
    import fluent.asserts;
    import mahjong.engine.opts;
	class TestMetagame : Metagame
	{
		this(bool nagashiMangan)
		{
			super([new Player(), new Player()], new DefaultGameOpts);
            if(!nagashiMangan)
            {
                players.each!(p => p.isNotNagashiMangan);
            }
		}

		private bool _isExhaustiveDraw;
		private bool _isAbortiveDraw;

		override bool isAbortiveDraw() @property
		{
			return _isAbortiveDraw;
		}
		override bool isExhaustiveDraw() @property const
		{
			return _isExhaustiveDraw;
		}
	}
    auto createGameAndSetFlowToTurnEndFlow(bool nagashiMangan = false)
    {
    	auto meta = new TestMetagame(nagashiMangan);
    	auto turnEndFlow = new TurnEndFlow(meta, new NullNotificationService);
    	switchFlow(turnEndFlow);
        return meta;
    }
}

@("Advance normally to draw flow")
unittest
{
    createGameAndSetFlowToTurnEndFlow;
	.flow.advanceIfDone;
    .flow.should.be.instanceOf!DrawFlow;
}

@("If the game is aborted, the flow should switch to the abortive draw flow")
unittest
{
    auto meta = createGameAndSetFlowToTurnEndFlow;
	meta._isAbortiveDraw = true;
	.flow.advanceIfDone;
    .flow.should.be.instanceOf!AbortiveDrawFlow;
}
@("If the game is aborted and exhausted, the flow should switch to the abortive draw flow")
unittest
{
    auto meta = createGameAndSetFlowToTurnEndFlow;
    meta._isAbortiveDraw = true;
	meta._isExhaustiveDraw = true;
	.flow.advanceIfDone;
    .flow.should.be.instanceOf!AbortiveDrawFlow;
}

@("If the game is exhausted, the flow should switch to the exhaustive draw flow")
unittest
{
    auto meta = createGameAndSetFlowToTurnEndFlow;	
    meta._isExhaustiveDraw = true;
	.flow.advanceIfDone;
    .flow.should.be.instanceOf!ExhaustiveDrawFlow;
}

@("If the game is exhausted and there is a nagashi mangan, the flow should switch to a mahjong flow")
unittest
{
    auto meta = createGameAndSetFlowToTurnEndFlow(true);  
    meta._isExhaustiveDraw = true;
    .flow.advanceIfDone;
    .flow.should.be.instanceOf!MahjongFlow;
}
