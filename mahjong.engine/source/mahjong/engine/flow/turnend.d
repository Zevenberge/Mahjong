module mahjong.engine.flow.turnend;

import std.experimental.logger;
import mahjong.domain;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class TurnEndFlow : Flow
{
	this(Metagame game, INotificationService notificationService)
	{
		super(game, notificationService);
	}
	
	override void advanceIfDone(Engine engine)
	{
		if(_metagame.isAbortiveDraw)
		{
			info("Abortive draw reached.");
			engine.switchFlow(new AbortiveDrawFlow(_metagame, _notificationService, engine));
		}
		else if(_metagame.isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
            if(_metagame.isAnyPlayerNagashiMangan)
            {
                engine.switchFlow(new MahjongFlow(_metagame, _notificationService, engine));
            }
            else
            {
                engine.switchFlow(new ExhaustiveDrawFlow(_metagame, _notificationService, engine));
            }
		}
		else
		{
			trace("Advancing to the next turn.");
			_metagame.advanceTurn;
			engine.switchFlow(new DrawFlow(_metagame.currentPlayer, _metagame, _metagame.wall, _notificationService));
		}
	}
}

version(unittest)
{
    import std.algorithm;
    import fluent.asserts;
	import unit_threaded : DontTest;
    import mahjong.domain.opts;
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
		auto engine = new Engine(meta);
    	auto turnEndFlow = new TurnEndFlow(meta, new NullNotificationService);
    	engine.switchFlow(turnEndFlow);
        return engine;
    }
	@DontTest
	auto testMetagame(Engine engine)
	{
		return cast(TestMetagame)engine.metagame;
	}
}

@("Advance normally to draw flow")
unittest
{
    auto engine = createGameAndSetFlowToTurnEndFlow;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!DrawFlow;
}

@("If the game is aborted, the flow should switch to the abortive draw flow")
unittest
{
    auto engine = createGameAndSetFlowToTurnEndFlow;
	engine.testMetagame._isAbortiveDraw = true;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!AbortiveDrawFlow;
}
@("If the game is aborted and exhausted, the flow should switch to the abortive draw flow")
unittest
{
    auto engine = createGameAndSetFlowToTurnEndFlow;
    engine.testMetagame._isAbortiveDraw = true;
	engine.testMetagame._isExhaustiveDraw = true;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!AbortiveDrawFlow;
}

@("If the game is exhausted, the flow should switch to the exhaustive draw flow")
unittest
{
    auto engine = createGameAndSetFlowToTurnEndFlow;	
    engine.testMetagame._isExhaustiveDraw = true;
	engine.advanceIfDone;
    engine.flow.should.be.instanceOf!ExhaustiveDrawFlow;
}

@("If the game is exhausted and there is a nagashi mangan, the flow should switch to a mahjong flow")
unittest
{
    auto engine = createGameAndSetFlowToTurnEndFlow(true);  
    engine.testMetagame._isExhaustiveDraw = true;
    engine.advanceIfDone;
    engine.flow.should.be.instanceOf!MahjongFlow;
}
