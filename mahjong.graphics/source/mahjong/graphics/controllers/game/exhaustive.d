module mahjong.graphics.controllers.game.exhaustive;

import dsfml.graphics : RenderWindow, Event, Keyboard;
import mahjong.domain.metagame;
import mahjong.domain.scoring;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.game;

class ExhaustiveDrawController : GameController
{
    this(const Metagame metagame,
        ExhaustiveDrawEvent event, Engine engine)
    {
        super(metagame, engine);
        _event = event;
    }

    private ExhaustiveDrawEvent _event;

    protected override void handleGameKey(Event.KeyEvent key)
    {
        if(key.code == Keyboard.Key.Return)
        {
            auto transactions = _metagame.calculateTenpaiTransactions;
            if(transactions)
            {
                Controller.instance.substitute(
                    new TransferController!ExhaustiveDrawEvent(
                        _metagame, freezeGameGraphicsOnATexture(_metagame),
                        _event, transactions, _engine));
            }
            else
            {
                _event.handle;
            }
        }
    }
}

@("If no-one is tenpai, the event will be handled after a return press")
unittest
{
    import fluent.asserts;
    import mahjong.domain.opts;
    import mahjong.domain.player;
    import mahjong.test.key;
    scope(exit) setDefaultTestController;
    setDefaultTestController;
    auto player = new Player;
    player.willNotBeTenpai;
    auto metagame = new Metagame([player, player, player, player], new DefaultGameOpts);
    auto event = new ExhaustiveDrawEvent(metagame);
    auto engine = new Engine(metagame);
    Controller.instance.substitute(new ExhaustiveDrawController(metagame, event, engine));
    Controller.instance.handleEvent(returnKeyPressed);
    event.isHandled.should.equal(true);
}

@("If someone is tenpai, a new controller will be spawned instead")
unittest
{
    import fluent.asserts;
    import mahjong.domain.opts;
    import mahjong.domain.player;
    import mahjong.test.key;
    scope(exit) setDefaultTestController;
    setDefaultTestController;
    auto player = new Player;
    player.willNotBeTenpai;
    auto tenpaiPlayer = new Player;
    tenpaiPlayer.willBeTenpai;
    auto metagame = new Metagame([tenpaiPlayer, player, player, player], new DefaultGameOpts);
    auto event = new ExhaustiveDrawEvent(metagame);
    auto engine = new Engine(metagame);
    Controller.instance.substitute(new ExhaustiveDrawController(metagame, event, engine));
    Controller.instance.handleEvent(returnKeyPressed);
    event.isHandled.should.equal(false);
    Controller.instance.should.be.instanceOf!(TransferController!ExhaustiveDrawEvent);
}