module mahjong.graphics.eventhandler;

import std.experimental.logger;
import mahjong.domain.opts;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.drawing.ingame;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.popup.service;

Engine bootEngine(GameEventHandler[] eventHandlers, const Opts opts)
in(eventHandlers.length > 0, "Non-player event handlers should be supplied")
{
    auto uiEventHandler = new UiEventHandler;
    auto allEventHandlers = [cast(GameEventHandler)uiEventHandler] ~ eventHandlers;
    auto engine = new Engine(allEventHandlers, opts, new PopupService);
    uiEventHandler._engine = engine;
    engine.boot;
    return engine;
}

class UiEventHandler : GameEventHandler
{
    private this() {}

    private Engine _engine;

	override void handle(TurnEvent event) 
	{
		info("UI: Handling turn event by switching controller");
        if(!event.player.isRiichi)
        {
            Controller.instance.substitute(
                new TurnController(event.metagame, event, _engine)
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
                    new TurnOptionController(event.metagame, 
                        Controller.instance, factory, _engine)
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
        import mahjong.domain.opts;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        scope(exit) Controller.cleanUp;
        auto player = new Player;
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto event = new TurnEvent(metagame, player, player.lastTile);
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
        import mahjong.domain.opts;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        import mahjong.domain.wall;
        import mahjong.engine.notifications;
        scope(exit) Controller.cleanUp;
        auto player = new Player;
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        player.game = new Ingame(PlayerWinds.east, "🀀🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d);
        player.declareRiichi(player.closedHand.tiles[0], metagame);
        auto eventHandler = new UiEventHandler;
        auto engine = new Engine(metagame, [eventHandler]);
        auto wall = new MockWall(new Tile(Types.ball, Numbers.eight));
        player.drawTile(wall);
        auto flow = new TurnFlow(player, metagame, new NullNotificationService, engine);
        engine.switchFlow(flow);
        Controller.instance.should.not.be.instanceOf!TurnController;
        engine.advanceIfDone;
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
        import mahjong.domain.opts;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        import mahjong.domain.wall;
        import mahjong.engine.notifications;
        scope(exit) Controller.cleanUp;
        auto player = new Player;
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        player.game = new Ingame(PlayerWinds.east, "🀀🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗🀗"d);
        player.declareRiichi(player.closedHand.tiles[0], metagame);
        auto wall = new MockWall(new Tile(Types.ball, Numbers.nine));
        player.drawTile(wall);
        auto event = new TurnEvent(metagame, player, player.lastTile);
        auto eventHandler = new UiEventHandler;
        eventHandler.handle(event);
        Controller.instance.should.be.instanceOf!TurnOptionController;
    }
	
	override void handle(GameStartEvent event)
	{
		info("UI: Handling game start event by creating an idle controller");
		Controller.instance.substitute(new IdleController(event.metagame, _engine));
		event.handle;
	}

	override void handle(RoundStartEvent event)
	{
		clearIngameCache;
		event.handle;
	}

	override void handle(ClaimEvent event) 
	{
		auto factory = new ClaimOptionFactory(event.player, event.tile, event.metagame, event);
		if(factory.areThereClaimOptions)
		{
			info("UI: Handling turn event by switching to the claim controller");
			Controller.instance.substitute(new ClaimController(event.metagame, Controller.instance, factory, _engine));
		}
		else
		{
			event.pass();
		}
	}

    override void handle(KanStealEvent event)
    {
        if(event.canSteal)
        {
            auto factory = new KanStealOptionsFactory(event);
            Controller.instance.substitute(
                new KanStealOptionController(
                    event.metagame, Controller.instance, factory, _engine));
        }
        else
        {
            event.pass();
        }
    }

    @("If I cannot steal the tile, the event gets automatically handled")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.metagame;
        import mahjong.domain.opts;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        auto tile = new Tile(Types.wind, Winds.east);
        auto player = new Player("🀀🀀🀁🀁🀁"d);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto event = new KanStealEvent(tile, player, metagame);
        auto eventHandler = new UiEventHandler();
        eventHandler.handle(event);
        event.isHandled.should.equal(true);
    }

    @("If I can steal the tile, I get a special menu")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        import mahjong.domain.metagame;
        import mahjong.domain.opts;
        import mahjong.domain.player;
        import mahjong.domain.tile;
        scope(exit) Controller.cleanUp;
        auto tile = new Tile(Types.wind, Winds.east);
        auto player = new Player("🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto event = new KanStealEvent(tile, player, metagame);
        auto eventHandler = new UiEventHandler();
        eventHandler.handle(event);
        event.isHandled.should.equal(false);
        Controller.instance.should.be.instanceOf!KanStealOptionController;
    }

	override void handle(MahjongEvent event)
	{
		Controller.instance.substitute(new MahjongController(event.metagame, event, _engine));
	}

    override void handle(ExhaustiveDrawEvent event)
	{
		Controller.instance.substitute(new ExhaustiveDrawController(event.metagame, event, _engine));
	}

    override void handle(AbortiveDrawEvent event)
    {
        Controller.instance.substitute(new AbortiveDrawController(event.metagame, event, _engine));
    }

	override void handle(GameEndEvent event) 
	{
		Controller.instance.substitute(new GameEndController(event.metagame, event, _engine));
	}

}
