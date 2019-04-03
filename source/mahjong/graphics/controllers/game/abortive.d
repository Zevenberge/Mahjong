module mahjong.graphics.controllers.game.abortive;

import dsfml.graphics : RenderWindow, Event, Keyboard;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.engine.flow.traits;
import mahjong.graphics.controllers.game;

alias AbortiveDrawController = HandleSimpleEventController!AbortiveDrawEvent;

class HandleSimpleEventController(TEvent) : GameController
{
    this(RenderWindow window, const Metagame metagame,
        TEvent event)
    {
        super(window, metagame);
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