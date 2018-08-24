module mahjong.graphics.eventhandler;

import std.experimental.logger;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.drawing.ingame;
import mahjong.graphics.drawing.tile;

class UiEventHandler : GameEventHandler
{
	override void handle(TurnEvent event) 
	{
		info("UI: Handling turn event by switching controller");
        if(!event.player.isRiichi)
        {
            Controller.instance.substitute(
                new TurnController(Controller.instance.getWindow, event.metagame, event)
                );
        }
        else
        {
            auto factory = new TurnOptionFactory(event.drawnTile, event, false);
            if(factory.isDiscardTheOnlyOption)
            {
                event.discard(event.drawnTile);
            }
            else
            {
                event.drawnTile.display;
                Controller.instance.substitute(
                    new TurnOptionController(Controller.instance.getWindow, event.metagame, 
                        Controller.instance, factory)
                    );
            }
        }
	}

    @("If the player is not riichi, the control of the turn is laid by the player")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.metagame;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        import mahjong.engine.opts;
        scope(exit) Controller.cleanUp;
        auto player = new Player;
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto event = new TurnEvent(null, metagame, player, player.lastTile);
        auto eventHandler = new UiEventHandler;
        eventHandler.handle(event);
        Controller.instance.should.be.instanceOf!TurnController;
    }

    @("If the player is riichi, but the drawn tile is not a winning tile, it should immediately be discarded")
    unittest
    {
        import std.algorithm.searching : any;
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.ingame;
        import mahjong.domain.metagame;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        import mahjong.domain.wall;
        import mahjong.engine.notifications;
        import mahjong.engine.opts;
        scope(exit) Controller.cleanUp;
        scope(exit) .flow = null;
        auto player = new Player;
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        player.game = new Ingame(PlayerWinds.east, "🀀🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d);
        player.declareRiichi(player.closedHand.tiles[0], metagame);
        auto wall = new MockWall(new Tile(Types.ball, Numbers.eight));
        player.drawTile(wall);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        auto event = new TurnEvent(flow, metagame, player, player.lastTile);
        auto eventHandler = new UiEventHandler;
        eventHandler.handle(event);
        Controller.instance.should.not.be.instanceOf!TurnController;
        player.closedHand.tiles.length.should.equal(13);
        player.closedHand.tiles
            .any!(tile => ComparativeTile(Types.ball, Numbers.eight).hasEqualValue(tile))
                .should.equal(false);
    }

    @("If the player is riichi and the drawn tile is a winning tile, the player should have a choice to tsumo")
    unittest
    {
        import std.algorithm.searching : any;
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.ingame;
        import mahjong.domain.metagame;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        import mahjong.domain.wall;
        import mahjong.engine.notifications;
        import mahjong.engine.opts;
        scope(exit) Controller.cleanUp;
        scope(exit) .flow = null;
        auto player = new Player;
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        player.game = new Ingame(PlayerWinds.east, "🀀🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d);
        player.declareRiichi(player.closedHand.tiles[0], metagame);
        auto wall = new MockWall(new Tile(Types.ball, Numbers.nine));
        player.drawTile(wall);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService);
        auto event = new TurnEvent(flow, metagame, player, player.lastTile);
        auto eventHandler = new UiEventHandler;
        eventHandler.handle(event);
        Controller.instance.should.be.instanceOf!TurnOptionController;
    }
	
	override void handle(GameStartEvent event)
	{
		info("UI: Handling game start event by creating an idle controller");
		Controller.instance.substitute(new IdleController(Controller.instance.getWindow, event.metagame));
		event.isReady = true;
	}

	override void handle(RoundStartEvent event)
	{
		clearIngameCache;
		event.isReady = true;
	}

	override void handle(ClaimEvent event) 
	{
		auto factory = new ClaimOptionFactory(event.player, event.tile, event.metagame, event);
		if(factory.areThereClaimOptions)
		{
			info("UI: Handling turn event by switching to the claim controller");
			Controller.instance.substitute(new ClaimController(Controller.instance.getWindow, event.metagame, Controller.instance, factory));
		}
		else
		{
			event.handle(new NoRequest);
		}
	}

	override void handle(MahjongEvent event)
	{
		Controller.instance.substitute(new ResultController(Controller.instance.getWindow, event.metagame, event));
	}

    override void handle(AbortiveDrawEvent event)
    {

    }

	override void handle(GameEndEvent event) 
	{
		Controller.instance.substitute(new GameEndController(Controller.instance.getWindow, event.metagame, event));
	}

}
