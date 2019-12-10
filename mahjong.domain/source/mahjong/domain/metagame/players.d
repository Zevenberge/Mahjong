module mahjong.domain.metagame.players;

import std.algorithm;
import std.range;
import mahjong.domain.mahjong;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.wrappers;
import mahjong.util.range;

inout(Player) currentPlayer(inout(Metagame) metagame) @property pure @nogc nothrow
{
    with(metagame)
    {
        return _turn == -1 ? null : players[_turn];
    }
}

Player currentPlayer(Metagame metagame, Player player) @property @nogc nothrow
{
    with(metagame)
    {
        _turn = players.indexOf(player);
    }
    return player;
}

inout(Player) nextPlayer(inout Metagame metagame) @property pure @nogc nothrow
{
    with(metagame)
    {
        return players[(_turn+1)%$];
    }
}

@("Is the initial next player south?")
unittest
{
    import fluent.asserts;
    import mahjong.domain.enums;
    import mahjong.domain.opts;
    auto metagame = new Metagame([new Player, new Player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    metagame.nextPlayer.wind.should.equal(PlayerWinds.south);
}

struct OtherPlayers(Metagame)
{
    private this(Metagame metagame, const Player playerToExclude)
    {
        _metagame = metagame;
        _playerToExclude = playerToExclude;
        _index = 0;
        if(front is playerToExclude) popFront;
    }

    private Metagame _metagame;
    private const Player _playerToExclude;
    private size_t _index;

    auto front() pure @nogc nothrow
    {
        assert(!empty);
        return _metagame.players[_index];
    }

    void popFront() pure @nogc nothrow
    {
        _index++;
        if(!empty && front is _playerToExclude)
        {
            popFront;
        }
    }

    bool empty() pure @nogc nothrow
    {
        return _index >= _metagame.players.length;
    }
}

auto otherPlayers(Metagame metagame) pure @nogc nothrow
{
    return OtherPlayers!(Metagame)(metagame, metagame.currentPlayer);
}

auto otherPlayers(const Metagame metagame, const Player player) pure @nogc nothrow
{
    return OtherPlayers!(const Metagame)(metagame, player);
}

AmountOfPlayers amountOfPlayers(const Metagame metagame) @property pure @nogc nothrow
{
    return AmountOfPlayers(metagame.players.length);
}

package inout(Player) eastPlayer(inout(Metagame) metagame) @property pure @nogc nothrow
{
    with(metagame)
    {
        return players[($-_round.roundStartingPosition)%$];
    }
}

auto playersByTurnOrder(Metagame metagame) @property pure @nogc nothrow
{
    return metagame.players.cycle
        .find!"a is b"(metagame.currentPlayer)
        .atLeastOneUntil(metagame.currentPlayer);
}

unittest
{
    import fluent.asserts;
    import mahjong.domain.opts;
    auto player1 = new Player;
    auto player2 = new Player;
    auto player3 = new Player;
    auto player4 = new Player;
    auto metagame = new Metagame([player1, player2, player3, player4], new DefaultGameOpts);
    metagame.currentPlayer = player3;
    metagame.playersByTurnOrder.should.equal(
        [player3, player4, player1, player2]
        );
}

bool isAnyPlayerNagashiMangan(const Metagame metagame) pure @nogc nothrow
{
    return metagame.players.any!(p => p.isNagashiMangan);
}

bool isAnyPlayerMahjong(const Metagame metagame) pure @nogc nothrow
{
    return metagame.players.any!(p => p.isMahjong);
}