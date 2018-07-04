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
	
	final void animate()
	{
		animateAllAnimations;
	}
}

interface ISubstituteInnerController
{
	void substitute(Controller newController);
}

public Controller controller() {return _controller;} @property pure
private Controller _controller;

void trySwitchController(Controller newController)
{
	info("Trying to switch to controller ", typeid(newController));
	auto switchableController = cast(ISubstituteInnerController)_controller;
	if(switchableController) {
		info("Substituting inner controller.");
		info("Inner controller is ", switchableController);
		switchableController.substitute(newController);
	}
	else {
		switchController(newController);
	}
}

bool isLeadingController(Controller this_)
{
	return _controller is this_;
}

void forceSwitchController(Controller newController)
{
	info("Forcing the switch of controllers");
	switchController(newController);
}

private void switchController(Controller newController)
{
	info("Switching to new controller of type ", newController);
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