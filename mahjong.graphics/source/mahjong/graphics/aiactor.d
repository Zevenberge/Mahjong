module mahjong.graphics.aiactor;

import mahjong.ai;
import mahjong.domain.player;
import mahjong.engine.flow;
import mahjong.engine.flow.traits;
import mahjong.graphics.parallelism;

GameEventHandler[amountOfHandlers] runInBackground(size_t amountOfHandlers)(AI ai, BackgroundWorker bg)
{
    auto actor = new AiActor(bg.reference, ai);
    bg.changeWorker(actor);
    auto uiThread = new ApplyOnUiThreadActor();
    bg.changeListener(uiThread);
    GameEventHandler[amountOfHandlers] handlers = void;
    foreach(i; 0 .. amountOfHandlers)
    {
        handlers[i] = new ParallelEventHandler(uiThread, bg);
    }
    return handlers;
}

private:
class ParallelEventHandler : GameEventHandler
{
    this(ApplyOnUiThreadActor actor, BackgroundWorker worker)
    {
        _actor = actor;
        _worker = worker;
    }

    private ApplyOnUiThreadActor _actor;
    private BackgroundWorker _worker;

    import std.meta : AliasSeq;
    static foreach(Event; AliasSeq!(TurnEvent, KanStealEvent, ClaimEvent))
    {
        override void handle(Event event)
        {
            _actor.register(event);
            _worker.sendMessage(event);
        }
    }
	mixin HandleSimpleEvents!();	
}

class ApplyOnUiThreadActor : Actor
{
    import std.algorithm : all, each, filter;
    import std.conv : to;
    import std.meta : AliasSeq;
    alias Pairs = AliasSeq!(
        TurnEvent, TurnDecision,
        KanStealEvent, KanStealDecision,
        ClaimEvent, ClaimDecision
    );
    static foreach(i; 0 .. Pairs.length/2)
    {
        mixin(`Pairs[2*i][] _events` ~ i.to!string ~ `;`);
        private void register(Pairs[2*i] event)
        {
            mixin(`_events` ~ i.to!string ~ ` ~= event;`);
        }

        void handle(const Pairs[2*i+1] decision)
        {
            mixin(`alias events = _events` ~ i.to!string  ~ `;`);
            foreach(event; events.filter!(e => e.player is decision.player))
            {
                event.apply(decision);
            }
            //events.filter!(e => e.player is decision.player)
            //    .each(e => apply(e, decision));
            if(events.all!(e => e.isHandled))
            {
                events.length = 0;
            }
        }
    }
    mixin Handle;
}

class AiActor : Actor
{
    this(ActorRef sender, AI ai)
    {
        _ai = ai;
        _sender = sender;
    }

    private AI _ai;
    private ActorRef _sender;

    import std.meta : AliasSeq;
    static foreach(Event; AliasSeq!(TurnEvent, KanStealEvent, ClaimEvent))
    {
        void handle(const Event event)
        {
            const decision = _ai.decide(event);
            _sender.send(decision);
        }
    }

    mixin Handle;
}
