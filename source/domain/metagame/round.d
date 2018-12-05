module mahjong.domain.metagame.round;

import std.algorithm;
import std.conv;
import std.random;
import mahjong.domain.enums;
import mahjong.domain.metagame;
import mahjong.domain.wrappers;
import mahjong.engine.mahjong;
import mahjong.engine.scoring;
import mahjong.share.range;

package struct Round
{
    static Round createRandom(AmountOfPlayers amountOfPlayers)
    {
        return Round(uniform(0, amountOfPlayers));
    }

    version(unittest)
    {
        static Round withCounters(size_t amountOfCounters)
        {
            auto random = createRandom(AmountOfPlayers(4));
            random._counters = amountOfCounters;
            return random;
        }
    }

    uint number() @property pure const
    {
        return _number;
    }

    PlayerWinds leadingWind() @property pure const
    {
        return _leadingWind;
    }

    size_t roundStartingPosition() @property pure const
    {
        return _roundStartingPosition;
    }

    size_t counters() @property pure const
    {
        return _counters;
    }

    uint amountOfRiichiSticks() @property pure const
    {
        return _amountOfRiichiSticks;
    }

    void addRiichiStick() pure
    {
        ++_amountOfRiichiSticks;
    }

    void removeRiichiStick() pure
    {
        --_amountOfRiichiSticks;
    }

    this(size_t roundStartingPosition)
    {
        _number = 1;
        _leadingWind = PlayerWinds.east;
        _roundStartingPosition = roundStartingPosition;
        _counters = 0;
        _amountOfRiichiSticks = 0;
    }

private :
    uint _number;
    PlayerWinds _leadingWind;
    size_t _roundStartingPosition;

    void increment() pure
    {
        _number++;
    }

    void moveWinds(AmountOfPlayers amountOfPlayers, size_t leadingWindStartingLocation) pure
    {
        _roundStartingPosition = ((_roundStartingPosition - 1 + amountOfPlayers) % 
                                    amountOfPlayers).to!int;
        if(leadingWindStartingLocation == _roundStartingPosition)
        {
            _leadingWind = (_leadingWind + 1).to!PlayerWinds;
            _number = 1;
        }
    }

    size_t _counters;
    uint _amountOfRiichiSticks;

    void addCounter() pure
    {
        _counters++;
    }

    void resetCounter() pure
    {
        _counters = 0;
    }

    void removeRiichiSticks() pure
    {
        _amountOfRiichiSticks = 0;
    }
}

package Round finishRoundWithMahjong(Metagame metagame, Round round)
{
    auto transactions = metagame.constructMahjongData.toTransactions(metagame);
    metagame.applyTransactions(transactions);
    round.increment;
    round.removeRiichiSticks;
    bool needToMoveWinds = !metagame.eastPlayer.isMahjong;
    if(needToMoveWinds)
    {
        round.resetCounter;
        round.moveWinds(metagame.amountOfPlayers, metagame._leadingWindStartingLocation);
    }
    else
    {
        round.addCounter;
    }
    return round;
}

package Round finishRoundWithExhaustiveDraw(Metagame metagame, Round round)
{
    if(metagame.players.any!(p => p.isNagashiMangan))
    {
        return finishRoundWithMahjong(metagame, round);
    }
    round.addCounter;
    bool needToMoveWinds = !metagame.eastPlayer.isTenpai;
    if(needToMoveWinds)
    {
        round.moveWinds(metagame.amountOfPlayers, metagame._leadingWindStartingLocation);
    }
    return round;
}

private void applyTransactions(Metagame metagame, Transaction[] transactions)
{
    foreach(transaction; transactions)
    {
        auto player = metagame.players.first!(p => p == transaction.player);
        player.applyTransaction(transaction);
    }
}
