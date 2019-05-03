module mahjong.graphics.parallelism;

import core.time;
import std.concurrency;
import std.process;
import dsfml.system.thread;
import mahjong.engine.flow;
import mahjong.engine.flow.traits;
import std.stdio;

auto inBackground(T)(T eventHandler, BackgroundWorker bg)
{
    return new Background!T(eventHandler, bg);
}

class BackgroundWorker
{
    import dsfml.graphics.renderwindow;
    this(RenderWindow window)
    {
        window.setActive(false);
        _worker = spawn(&listen, thisTid);
    }

    void stop()
    {
        _worker.send(Kill());
    }

    Tid _worker;

    void sendMessage(Message)(const Message message)
    {
        shared const Message shMes = cast(shared)message;
        send(_worker, shMes);
    }

    void poll(T...)(T ops)
    {
        receiveTimeout(-1.msecs, ops);
    }
}

void listen(Tid parent)
{
    import std.concurrency, std.stdio;;
    import std.variant;
    bool shouldContinue = true;
    while(shouldContinue)
    {
        receive(
            (Kill _) {shouldContinue = false;},
            (shared const TurnEvent ev) { writeln("Turnevent received"); parent.send(42);},
            (Variant v) { writeln("Got a surprise: ", v);});

    }
}

private struct Kill{}

class Background(T) : GameEventHandler
{
    this(T worker, BackgroundWorker bg)
    {
        _worker = worker;
        _bg = bg;
    }

    private T _worker;
    private BackgroundWorker _bg;

	mixin HandleSimpleEvents!();

    static foreach(handler; __traits(getOverloads, GameEventHandler, "handle"))
    {
        import std.traits;
        static if(!isSimpleEvent!(Parameters!handler[0]))
        {
            pragma(msg, "Generating background method for " ~ Parameters!handler[0].stringof);
            override void handle(Parameters!handler[0] event)
            {
                writeln("Handling event");
                _worker.handle(event);
                _bg.sendMessage(event);
            }
        }
    }
}

