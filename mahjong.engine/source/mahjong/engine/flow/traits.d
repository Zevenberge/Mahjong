module mahjong.engine.flow.traits;

template isSimpleEvent(TEvent)
{
    import std.traits : hasMember, Parameters, Fields;
    pragma(msg, "Checking is simple event for "~TEvent.stringof);
    static foreach(field; Fields!TEvent){} // HACK to force the evaluation of mixin templates.

    enum isSimpleEvent = __traits(compiles, (TEvent.init).handle());
}

mixin template SimpleEvent(string file = __FILE__)
{
    pragma(msg, "Generating simple event boilerplate for "~file);
    private bool _isHandled;

	bool isHandled() @property pure const
	{
		return _isHandled;
	}

	void handle() pure
	{
		_isHandled = true;
	}
}

@("Is a simple event a simple event")
unittest
{
    import fluent.asserts;

    class SimpleEvent
    {
        bool isHandled()
        {
            return true;
        }

        void handle()
        {
        }
    }

    isSimpleEvent!SimpleEvent.should.equal(true);
}

@("Is a complex event not a simple event")
unittest
{
    import fluent.asserts;

    class ComplexEvent
    {
        bool isHandled()
        {
            return true;
        }

        void handle(bool decisionOfYourLife)
        {
        }
    }

    isSimpleEvent!ComplexEvent.should.equal(false);
}

@("Is an event with non trivial handlers not a simple event")
unittest
{
    import fluent.asserts;

    class NonTrivialEvent
    {
        bool isHandled()
        {
            return true;
        }

        void marry()
        {
        }

        void foreverAlone()
        {
        }
    }

    isSimpleEvent!NonTrivialEvent.should.equal(false);
}

mixin template HandleSimpleEvents()
{
    import mahjong.engine.flow.eventhandler;
    static foreach(handler; __traits(getOverloads, GameEventHandler, "handle"))
    {
        import std.traits;
        static if(isSimpleEvent!(Parameters!handler[0]))
        {
            pragma(msg, "Generating method for " ~ Parameters!handler[0].stringof);
            override void handle(Parameters!handler[0] event)
            {
                event.handle();
            }
        } else pragma(msg, "Skipping method generation for "~Parameters!handler[0].stringof);
    }
}

version(unittest)
{
    import mahjong.engine.flow;
    abstract class AutoHandler : GameEventHandler
    {
        mixin HandleSimpleEvents!();
    }
}

@("Simple events should be handled")
unittest
{
    import std.typecons : WhiteHole;
    import fluent.asserts;
    
    alias AutoHandlerImpl = WhiteHole!AutoHandler;
    auto event = new GameStartEvent(null);
    auto handler = new AutoHandlerImpl();
    handler.handle(event);
    event.isHandled.should.equal(true);
}