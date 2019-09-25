module mahjong.graphics.controllers.controller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.anime.animation;

abstract class Controller
{
	final bool handleEvent(Event event)
	{
        if(event.type == event.EventType.Closed) return true;
        if(propagateToOverlays(event)) return false;
		switch(event.type) with(event.EventType)
		{
			case KeyReleased:
				return handleKeyEvent(event.key);
			default:
				return false;
		}
	}

    @("If I close the window, the controller should acknowledge it")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.window;
        auto controller = new TestController;
        controller.handleEvent(windowClosed).should.equal(true);
    }

    @("If I close the window while there are overlays, the controller should still acknowledge it")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.window;
        auto controller = new TestController;
        controller.add(new SomeOverlay);
        controller.handleEvent(windowClosed).should.equal(true);
    }

    private bool propagateToOverlays(Event event)
    {
        import std.algorithm.iteration : fold;
        return _overlays.fold!((handled, overlay) => overlay.handle(event) || handled)(false);
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

    protected final void removeAllOverlays() @safe pure nothrow @nogc
    {
        _overlays = null;
    }

    protected final void drawOverlays(RenderTarget target)
    {
        foreach(overlay; _overlays)
        {
            overlay.draw(target);
        }
    }

    @("I can draw my overlays")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.window;
        class MyOverlay : Overlay
        {
            this(Drawable d)
            {
                this.d = d;
            }

            Drawable d;

            override void draw(RenderTarget target) 
            {
                target.draw(d);
            }

            override bool handle(Event event)
            {
                return false;
            }
        }
        auto txt = new Text();
        auto target = new TestWindow();
        auto overlay = new MyOverlay(txt);
        auto controller = new TestController;
        controller.add(overlay);
        controller.drawOverlays(target);
        target.drawnObjects.length.should.equal(1);
        target.drawnObjects[0].should.equal(txt);
    }

    version(unittest)
    {
        final bool has(Overlay overlay)
        {
            import std.algorithm: any;
            return _overlays.any!(o => o is overlay);
        }
    }

    final bool has(TOVerlay : Overlay)() @safe pure @nogc nothrow
    {
        import std.algorithm: any;
        return _overlays.any!(o => cast(TOVerlay)o !is null);
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
    abstract bool handle(Event event);
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

        override bool handle(Event event)
        {
            return false;
        }
    }

	void setDefaultTestController()
	{
		Controller._instance = new TestController;
	}
}