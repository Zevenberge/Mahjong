module mahjong.graphics.integration_test;

version(unittest)
{
    import std.datetime.stopwatch;
    import fluent.asserts;
    import mahjong.ai;
    import mahjong.ai.advanced;
    import mahjong.domain.enums;
    import mahjong.domain.ingame;
    import mahjong.domain.metagame;
    import mahjong.domain.opts;
    import mahjong.domain.player;
    import mahjong.domain.tile;
    import mahjong.engine;
    import mahjong.engine.flow;
    import mahjong.engine.notifications;
    import mahjong.graphics.controllers;
    import mahjong.graphics.eventhandler;
    import mahjong.graphics.opts;
    import mahjong.graphics.popup.service;
    import mahjong.test.key;
    import mahjong.test.window;
}

/+
@("Can I activate a claim while a popup is being shown")
unittest
{
    scope(exit) Controller.cleanUp;
    styleOpts = new DefaultStyleOpts;
    auto tile = new Tile(Types.wind, Winds.east);
    tile.isNotOwn;
    auto player = new Player(PlayerWinds.east);
    auto opts = new DefaultGameOpts;
    auto metagame = new Metagame([player], opts);
    metagame.initializeRound;
    player.game = new Ingame(PlayerWinds.east, "🀀🀀🀁🀁🀁🀂🀂🀂🀃🀃🀐🀑🀒"d);
    auto event = new ClaimEvent(tile, player, metagame);
    auto eventHandler = new UiEventHandler();
    eventHandler.handle(new GameStartEvent(metagame));
    auto service = new PopupService;
    service.notify(Notification.Riichi);
    eventHandler.handle(event);
    event.isHandled.should.equal(false);
    auto window = new TestWindow;
    Controller.instance.draw(window);
    Controller.instance.handleEvent(returnKeyPressed); // Handle popup
    Controller.instance.handleEvent(returnKeyPressed); // Confirm event
    Controller.instance.should.be.instanceOf!IdleController;
}+/

@("Four AI players can win a battle")
unittest
{
    import core.time : seconds;
    auto ai = new AdvancedAI;
    auto engine = new Engine([new AiEventHandler(ai),
        new AiEventHandler(ai),
        new AiEventHandler(ai), 
        new AiEventHandler(ai)], new DefaultGameOpts,
        new NullNotificationService);
    engine.boot;
    auto sw = StopWatch(AutoStart.yes);
    while(!engine.isTerminated)
    {
        engine.advanceIfDone();
        if(sw.peek > 10.seconds)
        {
            assert(false, "AI did not finish their game within said time.");
        }
    }
}