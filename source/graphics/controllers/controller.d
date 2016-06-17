module mahjong.graphics.controllers.controller;

import dsfml.graphics;

abstract class Controller
{
	protected RenderWindow _window;
	
	protected this(RenderWindow window)
	{
		_window = window;
	}
	
	final bool handleEvent(Event event)
	{
		switch(event.type) with(event.EventType)
		{
			case Closed:
				return true;
			case KeyReleased:
				return handleKeyEvent(event.key);
			default:
				return false;
		}
	}
	
	protected abstract bool handleKeyEvent(Event.KeyEvent key);
	
	abstract void draw();
	
	abstract void roundUp();
	
	abstract void yield();
}

Controller controller;