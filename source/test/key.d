module mahjong.test.key;

import dsfml.window.event;
import dsfml.window.keyboard;

Event returnKeyPressed()
{
    Event keyEvent = Event(Event.EventType.KeyReleased);
    keyEvent.key = Event.KeyEvent(Keyboard.Key.Return, false, false, false, false);
    return keyEvent;
}