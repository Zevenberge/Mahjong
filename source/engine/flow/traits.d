module mahjong.engine.flow.traits;

template isSimpleEvent(TEvent)
{
    enum isSimpleEvent = __traits(compiles, (TEvent.init).handle());
}

unittest
{
    import mahjong.engine.flow;
    static assert(isSimpleEvent!ExhaustiveDrawEvent);
    static assert(!isSimpleEvent!TurnEvent);
}