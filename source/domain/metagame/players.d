module mahjong.domain.metagame.players;

import std.algorithm;
import std.range;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.wrappers;
import mahjong.share.range;

inout(Player) currentPlayer(inout(Metagame) metagame) @property pure
{
    with(metagame)
    {
        return _turn == -1 ? null : players[_turn];
    }
}

Player currentPlayer(Metagame metagame, Player player) @property
{
    with(metagame)
    {
        _turn = players.indexOf(player);
    }
    return player;
}

inout(Player) nextPlayer(inout Metagame metagame) @property pure
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
    import mahjong.engine.opts;
    auto metagame = new Metagame([new Player, new Player], new DefaultGameOpts);
    metagame.initializeRound;
    metagame.beginRound;
    metagame.nextPlayer.wind.should.equal(PlayerWinds.south);
}

auto otherPlayers(Metagame metagame) pure
{
    auto currentPlayer = metagame.currentPlayer;
    return metagame.players.filter!(p => p != currentPlayer);
}

auto otherPlayers(const Metagame metagame, const Player player) pure
{
    return metagame.players.filter!(p => p != player);
}

AmountOfPlayers amountOfPlayers(const Metagame metagame) @property pure
{
    return AmountOfPlayers(metagame.players.length);
}

package inout(Player) eastPlayer(inout(Metagame) metagame) @property pure
{
    with(metagame)
    {
        return players[($-_round.roundStartingPosition)%$];
    }
}

auto playersByTurnOrder(Metagame metagame) @property
{
    return metagame.players.cycle
        .find(metagame.currentPlayer)
        .atLeastOneUntil(metagame.currentPlayer);
}

unittest
{
    import fluent.asserts;
    import mahjong.engine.opts;
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

bool isAnyPlayerNagashiMangan(const Metagame metagame)
{
    return metagame.players.any!(p => p.isNagashiMangan);
}