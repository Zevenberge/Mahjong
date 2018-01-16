module mahjong.graphics.controllers.controller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.anime.animation;

class Controller
{
	protected RenderWindow _window;
	
	protected this(RenderWindow window)
	{
		_window = window;
	}
	
	final RenderWindow getWindow()
	{
		return _window;
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
	
	void animate()
	{
		animateAllAnimations;
	}
}

interface ISubstrituteInnerController
{
	void substitute(Controller newController);
}

public Controller controller() {return _controller;} @property pure
private Controller _controller;

void trySwitchController(Controller newController)
{
	auto switchableController = cast(ISubstrituteInnerController)_controller;
	if(switchableController) {
		switchableController.substitute(newController);
	}
	else {
		switchController(newController);
	}
}

void switchController(Controller newController)
{
	info("Switchint to new controller of type ", typeid(newController));
	_controller = newController;
}

version(unittest)
{
	class TestController : Controller
	{
		import mahjong.test.window;

		this()
		{
			super(new TestWindow);
		}

		override void draw() 
		{
		}

		override void roundUp() 
		{
		}

		override protected bool handleKeyEvent(Event.KeyEvent key) 
		{
			return false;
		}

		override void yield() 
		{
		}
	}

	void setDefaultTestController()
	{
		._controller = new TestController;
	}
}