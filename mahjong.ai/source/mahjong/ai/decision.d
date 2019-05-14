module mahjong.ai.decision;

import mahjong.domain.chi;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine.flow;

struct TurnDecision
{
    enum Action
    {
        discard,
        promoteToKan,
        declareClosedKan,
        claimTsumo,
        declareRiichi,
        declareRedraw
    }

    const Player player;
    Action action;
    const Tile selectedTile;
}

void apply(TurnEvent event, const TurnDecision decision)
{
    import mahjong.util.traits : EnumMembers;
    import std.traits: Parameters;
    template needsTile(string member) 
    {
        alias params = Parameters!(__traits(getMember, event, member));
        enum needsTile =  params.length == 1;
    }
    a: final switch(decision.action) with(TurnDecision.Action)
    {
    static foreach(member; EnumMembers!(TurnDecision.Action))
    {
        case member.value:
            static if(needsTile!(member.name))
            {
                __traits(getMember, event, member.name)(decision.selectedTile);
            }
            else
            {
                __traits(getMember, event, member.name)();
            }
            break a;
    }
    }
}

struct KanStealDecision
{
    const Player player;
    bool steal;
}

void apply(KanStealEvent event, const KanStealDecision decision)
{
    if(decision.steal) event.steal();
    else event.pass();
}

struct ClaimDecision
{
    this(const Player player, Request request)
    {
        this.player = player;
        this.request = request;
    }
    const Player player;
    Request request;
    const Tile chiTile1;
    const Tile chiTile2;
}

void apply(ClaimEvent event, const ClaimDecision decision)
{
    final switch(decision.request) with(Request)
    {
        case None:
            event.pass();
            break;
        case Chi:
            event.chi(ChiCandidate(decision.chiTile1, decision.chiTile2));
            break;
        case Pon:
            event.pon();
            break;
        case Kan:
            event.kan();
            break;
        case Ron:
            event.ron();
            break;
    }
}
