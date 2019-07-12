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
	
	abstract void roundUp()
    {
        _overlays = null;
    }

    @("The default implementation of round-up clears all overlays")
    unittest
    {
        import fluent.asserts;
        auto overlay = new SomeOverlay();
        auto controller = new NullController();
        controller.add(overlay);
        controller.roundUp;
        controller.has(overlay).should.equal(false);
    }
	
	abstract void yield();
	
	final void animate()
	{
		animateAllAnimations;
	}

    private Overlay[] _overlays;
    final void add(Overlay overlay)
    {
        _overlays ~= overlay;
    }

    @("Can I add an overlay")
    unittest
    {
        import fluent.asserts;
        auto overlay = new SomeOverlay();
        auto controller = new NullController();
        controller.add(overlay);
        controller.has(overlay).should.equal(true);
        controller._overlays.should.equal([overlay]);
    }

    final void remove(Overlay overlay) @safe pure nothrow @nogc
    {
        import mahjong.util.collections : removeInPlace;
        _overlays.removeInPlace(overlay);
    }

    @("Can I remove an overlay")
    unittest
    {
        import std.range : empty;
        import fluent.asserts;
        auto overlay = new SomeOverlay();
        auto controller = new NullController();
        controller.add(overlay);
        controller.remove(overlay);
        controller._overlays.empty.should.equal(true);
    }

    version(unittest)
    {
        final bool has(Overlay overlay)
        {
            import std.algorithm: any;
            return _overlays.any!(o => o is overlay);
        }

        final bool has(TOVerlay : Overlay)()
        {
            import std.algorithm: any;
            return _overlays.any!(o => cast(TOVerlay)o !is null);
        }
    }

    void substitute(Controller newController)
    {
        newController._overlays = _overlays;
        _overlays = null;
        instance = newController;
    }

    @("If I swap the instance, I can retrieve the new controller")
    unittest
    {
        import fluent.asserts;
        scope(exit) cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        Controller.instance.should.equal(controller);
    }

    @("If I swap the instance, overlays get transferred")
    unittest
    {
        import fluent.asserts;
        scope(exit) cleanUp;
        auto overlay = new SomeOverlay();
        auto initial = new TestController;
        Controller.instance.substitute(initial);
        Controller.instance.add(overlay);
        auto replacement = new TestController;
        Controller.instance.substitute(replacement);
        initial.has(overlay).should.equal(false);
        replacement.has(overlay).should.equal(true);
    }

    static Controller instance() @property
    {
        if(_instance) return _instance;
        trace("No controller set, therefore creating a new null controller");
        return new NullController;
    }

    @("Instance always returns something to prevent crashes")
    unittest
    {
        import fluent.asserts;
        _instance = null;
        instance.should.not.beNull;
    }

    protected final void instance(Controller controller) @property
    {
        trace("Swapping controller to ", controller);
        _instance = controller;
    }

    private static Controller _instance;


    protected final bool isLeadingController() @property const
    {
        return _instance is this;
    }

    version(unittest)
    {
        static void cleanUp()
        {
            _instance = null;
        }
    }
}

abstract class Overlay
{
    abstract void draw(RenderTarget target);
    abstract bool handle(Event.KeyEvent key);
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
        super.roundUp();
    }

    protected override bool handleKeyEvent(Event.KeyEvent key) 
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
            super.roundUp();
		}

		override protected bool handleKeyEvent(Event.KeyEvent key) 
		{
			return false;
		}

		override void yield() 
		{
		}
	}

    class SomeOverlay : Overlay
    {
        override void draw(RenderTarget target) 
        {
        }

        override bool handle(Event.KeyEvent key)
        {
            return false;
        }
    }

	void setDefaultTestController()
	{
		Controller._instance = new TestController;
	}
}