module mahjong.engine.flow.traits;

template isSimpleEvent(TEvent)
{
    enum isSimpleEvent = __traits(compiles, (TEvent.init).handle());
}

mixin template SimpleEvent()
{
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