module mahjong.graphics.controllers.game.abortive;

import dsfml.graphics : Event, Keyboard;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.flow.traits;
import mahjong.graphics.controllers.game;

alias AbortiveDrawController = HandleSimpleEventController!AbortiveDrawEvent;

class HandleSimpleEventController(TEvent) : GameController
{
    this(const Metagame metagame,
        TEvent event, Engine engine)
    {
        super(metagame, engine);
        _event = event;
    }

    private TEvent _event;

    protected override void handleGameKey(Event.KeyEvent key)
    {
        if(key.code == Keyboard.Key.Return)
        {
            _event.handle;
        }
    }
}