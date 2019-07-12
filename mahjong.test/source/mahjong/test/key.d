module mahjong.test.key;

import dsfml.window.event;
import dsfml.window.keyboard;

Event returnKeyPressed()
{
    Event keyEvent = Event(Event.EventType.KeyReleased);
    keyEvent.key = Event.KeyEvent(Keyboard.Key.Return, false, false, false, false);
    return keyEvent;
}

Event upKeyPressed()
{
    Event keyEvent = Event(Event.EventType.KeyReleased);
    keyEvent.key = Event.KeyEvent(Keyboard.Key.Up, false, false, false, false);
    return keyEvent;
}

Event downKeyPressed()
{
    Event keyEvent = Event(Event.EventType.KeyReleased);
    keyEvent.key = Event.KeyEvent(Keyboard.Key.Down, false, false, false, false);
    return keyEvent;
}

Event escapeKeyPressed()
{
    Event keyEvent = Event(Event.EventType.KeyReleased);
    keyEvent.key = Event.KeyEvent(Keyboard.Key.Escape, false, false, false, false);
    return keyEvent;
}

Event gKeyPressed()
{
    Event keyEvent = Event(Event.EventType.KeyReleased);
    keyEvent.key = Event.KeyEvent(Keyboard.Key.G, false, false, false, false);
    return keyEvent;
}