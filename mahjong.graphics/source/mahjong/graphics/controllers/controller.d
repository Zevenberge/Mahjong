module mahjong.graphics.controllers.controller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.anime.animation;

abstract class Controller
{
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
	
	abstract void draw(RenderTarget target);
	
	abstract void roundUp();
	
	abstract void yield();
	
	final void animate()
	{
		animateAllAnimations;
	}

    void substitute(Controller newController)
    {
        instance = newController;
    }

    static Controller instance() @property
    {
        if(_instance) return _instance;
        trace("No controller set, therefore creating a new null controller");
        return new NullController;
    }

    protected final bool isLeadingController() @property const
    {
        return _instance is this;
    }

    protected final void instance(Controller controller) @property
    {
        trace("Swapping controller to ", controller);
        _instance = controller;
    }
    private static Controller _instance;

    version(unittest)
    {
        static void cleanUp()
        {
            _instance = null;
        }
    }
}

class NullController : Controller
{
    this()
    {
        info("Creating new NullController");
    }

    override void draw(RenderTarget target) 
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

version(unittest)
{
	class TestController : Controller
	{
		override void draw(RenderTarget target) 
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
		Controller._instance = new TestController;
	}
}