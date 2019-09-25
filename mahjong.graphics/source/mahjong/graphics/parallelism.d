module mahjong.graphics.parallelism;

public import std.concurrency : Tid;
alias ActorRef = Tid;

import core.time;
import std.concurrency;
import std.experimental.logger;
import std.process;
import std.typecons;
import std.variant;

class BackgroundWorker
{
    import dsfml.graphics.renderwindow;
    this(RenderWindow window)
    {
        window.setActive(false);
        _worker = spawn(&listen);
        _listener = new DeadEnd;
    }

    void stop()
    {
        info("Stopping background work");
        _worker.send(Kill());
        _listener = new DeadEnd;
    }

    private ActorRef _worker;
    void changeWorker(const Actor actor)
    {
        sendMessage(actor);
    }

    private Actor _listener;
    void changeListener(Actor actor)
    {
        _listener = actor;
    }

    ActorRef reference() const
    {
        return thisTid;
    }

    void sendMessage(Message)(const Message message)
    {
        send(_worker, message);
    }

    void poll()
    {
        receiveTimeout(-1.msecs, 
            (Variant v) { _listener.receive(v); }
        );
    }
}

void send(Message)(ActorRef actor, const Message message)
{
    import std.concurrency : send;
    shared const Message shMes = cast(shared)message;
    send(actor, shMes);
}

alias DeadEnd = BlackHole!Actor;
interface Actor
{
    void receive(Variant message);
}

mixin template Handle()
{
    alias T = typeof(this);
    import std.experimental.logger;
    import std.traits;
    import std.variant : Variant;
    alias allMethods = __traits(derivedMembers, T);
    void receive(Variant message)
    {
        static foreach(member; allMethods)
        static if(isInstanceMethod!member)
        {
            static foreach(method; MemberFunctionsTuple!(T, member))
            static if(isActorMethod!method)
            {
                if(message.convertsTo!(SharedOf!(Parameters!method[0])))
                {
                    auto param = message.get!(SharedOf!(Parameters!method[0]));
                    method(cast(Parameters!method[0])param);
                    return;
                }
            }
        }
        error("Received unknown message: ", message);
    }
}

@("Is my actor delegated correctly?")
unittest
{
    import fluent.asserts;
    class TestActor : Actor
    {
        private int _message;
        void listen(int message)
        {
            _message = message;
        }

        mixin Handle!();
    }
    auto actor = new TestActor();
    shared int msg = 42;
    Variant wrapper = msg;
    actor.receive(wrapper);
    actor._message.should.equal(42);
}

@("Can I handle overloads?")
unittest
{
    import fluent.asserts;
    class OverloadedActor : Actor
    {
        private string receivedType;
        void foo(int msg)
        {
            receivedType = "int";
        }
        void foo(double msg)
        {
            receivedType = "double";
        }
        mixin Handle;
    }
    auto actor = new OverloadedActor();
    shared int number = 42;
    Variant w = number;
    actor.receive(w);
    actor.receivedType.should.equal("int");
    shared double text = 4.2;
    Variant s = text;
    actor.receive(s);
    actor.receivedType.should.equal("double");
}

template isInstanceMethod(string name)
{
    enum isInstanceMethod = name != "__ctor" || name != "__dtor";
}

template isActorMethod(alias method)
{
    import std.traits : Parameters;
    static if(Parameters!method.length != 1)
    {
        enum isActorMethod = false;
    } 
    else
    {
        enum isActorMethod = __traits(getProtection, method) == "public";
    }
}

private void listen()
{
    import mahjong.util.log : logAspect, writeThrowable;
    mixin(logAspect!(LogLevel.info, "Background thread listener loop"));
    scope(failure) info("Background thread died due to an error.");
    Actor listener = new DeadEnd();
    bool shouldContinue = true;
    while(shouldContinue)
    {
        mixin(logAspect!(LogLevel.trace, "Background thread receive event"));
        receive(
            (shared const Kill _) {
                info("Terminating background thread");
                shouldContinue = false;
            },
            (shared const Actor actor) {
                info("Switching actor");
                listener = cast(Actor)actor; 
            },
            (Variant v) {
                info("Received ", v);
                try
                {
                    listener.receive(v);
                }
                catch(Throwable e)
                {
                    writeThrowable(e);
                    throw e;
                }
            });
    }
}

private struct Kill{}


