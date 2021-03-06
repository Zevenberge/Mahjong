﻿module mahjong.domain.scoring;

import std.algorithm;
import std.array;
import std.conv;
import std.math;
import std.range;
import mahjong.domain.enums;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.result;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.domain.wrappers;
import mahjong.domain.yaku;
import mahjong.domain.mahjong;
import mahjong.domain.opts;
import mahjong.util.range;

Scoring calculateScoring(const MahjongData mahjong, const Metagame metagame)
{
    auto yaku = mahjong.result.determineYaku(mahjong.player, metagame);
    auto miniPoints = mahjong.calculateMiniPoints(metagame.leadingWind);
    auto amountOfDoras = mahjong.countAmountOfDoras(metagame.wall);
    return new Scoring(yaku, miniPoints, amountOfDoras, metagame.counters, mahjong.player.isClosedHand, metagame.amountOfPlayers);
}

class Scoring
{
    private this(const(Yaku)[] yakus, size_t miniPoints, 
        size_t amountOfDoras, size_t amountOfCounters,
        bool isClosedHand, AmountOfPlayers amountOfPlayers)
    {
        this.yakus = yakus;
        this.miniPoints = miniPoints.roundMiniPoints;
        this.amountOfDoras = amountOfDoras;
        this.amountOfCounters = amountOfCounters;
        _isClosedHand = isClosedHand;
        _amountOfPlayers = amountOfPlayers;
    }

    const(Yaku)[] yakus;
    const size_t miniPoints;
    const size_t amountOfDoras;
    const size_t amountOfCounters;
    private bool _isClosedHand;
    private AmountOfPlayers _amountOfPlayers;

    Payment calculatePayment(bool isWinningPlayerEast)
    {
        auto fan = yakus.sum!(yaku => yaku.convertToFan(_isClosedHand));
        fan += amountOfDoras;
        if(fan >= 5)
        {
            return calculatePaymentForLimitHands(fan, isWinningPlayerEast);
        }
        return calculatePaymentForNonLimitHands(fan, isWinningPlayerEast);
    }

    private Payment calculatePaymentForLimitHands(size_t amountOfFan, bool isWinningPlayerEast)
    {
        auto rawPayment = findRawPaymentForLimitHands(amountOfFan);
        return new Payment(rawPayment.east, rawPayment.nonEast, amountOfCounters, isWinningPlayerEast, _amountOfPlayers);
    }

    private Payment calculatePaymentForNonLimitHands(size_t amountOfFan, bool isWinningPlayerEast)
    {
        auto rawPayment = prelimitScores[amountOfFan][miniPoints];
        return new Payment(rawPayment.east, rawPayment.nonEast, amountOfCounters, isWinningPlayerEast, _amountOfPlayers);
    }
}

unittest
{
    auto scoring = new Scoring([Yaku.nagashiMangan], 30, 0, 0, false, AmountOfPlayers(4));
    auto payment = scoring.calculatePayment(false);
    assert(payment.east == 4000, "Payment should be issued for a mangan");
    assert(payment.nonEast == 2000, "Payment should be issued for a mangan");
    assert(payment.ron == 8000, "Payment should be issued for a mangan");
}

unittest
{
    auto scoring = new Scoring([Yaku.nagashiMangan], 30, 0, 1, false, AmountOfPlayers(4));
    auto payment = scoring.calculatePayment(false);
    assert(payment.east == 4100, "Every player should pay 100 extra for every counter");
    assert(payment.nonEast == 2100, "Every player should pay 100 extra for every counter");
    assert(payment.ron == 8300, "A grand total of 300 extra is paid.");
}

unittest
{
    auto scoring = new Scoring([Yaku.menzenTsumo, Yaku.fanpai, Yaku.rinshanKaihou], 46, 0, 0, false, AmountOfPlayers(4));
    auto payment = scoring.calculatePayment(false);
    assert(payment.east == 3200, "3 fan 50 is 3200 for east");
    assert(payment.nonEast == 1600, "3 fan 50 is 1600 for non-east");
    assert(payment.ron == 6400, "3 fan 50 is 6400 for all");
}

unittest
{
    auto scoring = new Scoring([Yaku.chiiToitsu], 25, 0, 0, false, AmountOfPlayers(4));
    auto payment = scoring.calculatePayment(false);
    // Tsumo is not possible.
    assert(payment.ron == 1600, "2 fan 25 mp equals 2000 in a non-east ron");
}

unittest
{
    auto scoring = new Scoring([Yaku.riichi], 30, 4, 0, false, AmountOfPlayers(4));
    auto payment = scoring.calculatePayment(false);
    assert(payment.ron == 8000, "1 yaku + 4 dora is a mangan");
}

class Payment
{
    this(int east, int nonEast, size_t counters, bool isWinningPlayerEast,
        AmountOfPlayers amountOfPlayers)
    {
        _amountOfPlayers = amountOfPlayers.value.to!int;
        auto extraPaymentForCounters = 100 * counters.to!int;
        this.east = east + extraPaymentForCounters;
        // If the winning player is east, all non-easy players pay the east level.
        this.nonEast = (isWinningPlayerEast ? east : nonEast) + extraPaymentForCounters;
    }

    private const int _amountOfPlayers;
    const int east;
    const int nonEast;
    int ron() @property
    {
        // Sum the payments of every player.
        return east + (_amountOfPlayers - 2) * nonEast;
    }
}

unittest
{
    auto payment = new Payment(2000, 1000, 0, false, AmountOfPlayers(4));
    assert(payment.east == 2000, "The east value should have been initialized at 2000");
    assert(payment.nonEast == 1000, "The non-east value should have been initialized at the base value of 1000");
    assert(payment.ron == 4000, "The ron payment should be east + 2*non-east");
}

unittest
{
    auto payment = new Payment(2000, 1000, 4, false, AmountOfPlayers(4));
    assert(payment.east == 2400, "Each player pays 400 extra");
    assert(payment.nonEast == 1400, "Each player pays 400 extra");
    assert(payment.ron == 5200, "Each players pays 400 extra, totalling 1200 extra");
}

unittest
{
    auto payment = new Payment(2000, 1000, 0, true, AmountOfPlayers(4));
    assert(payment.east == 2000, "The east value should again have been initialized at 2000");
    assert(payment.nonEast == 2000, "Because east won, the non-east players also pay 2000");
    assert(payment.ron == 6000, "The ron payment should be 3*east");
}

unittest
{
    auto payment = new Payment(2000, 1000, 0, false, AmountOfPlayers(2));
    assert(payment.east == 2000, "The east value should have been initialized at 2000");
    // Non east is not actually relevant.
    assert(payment.ron == 2000, "The ron payment should be simply east, because there are no other players.");
}

unittest
{
    auto payment = new Payment(2000, 1000, 0, true, AmountOfPlayers(2));
    assert(payment.east == 2000, "The east value should have been initialized at 2000 and is invariant of who won.");
    // Non east is not actually relevant.
    assert(payment.ron == 2000, "The ron payment should be simply east, because there are no other players and is invariant of who won.");
}

unittest
{
    auto payment = new Payment(2000, 1000, 3, true, AmountOfPlayers(2));
    assert(payment.east == 2300, "The payment should be upped by 100 for each counter.");
    // Non east is not actually relevant.
    assert(payment.ron == 2300, "As there is only one other player, the total payment is also upped with only 100 per counter..");
}

Transaction[] toTransactions(const(MahjongData)[] data, const Metagame metagame)
{
    auto mahjongTransactions = data.flatMap!(d => extractTransactions(d, metagame));
    auto riichiTransactions = getRiichiTransactions(metagame, data);
    auto allTransactions = chain(mahjongTransactions, riichiTransactions);
    return allTransactions.mergeTransactions;
}

@("A win in a two-player game results in a plus and a minus transaction")
unittest
{
    import fluent.asserts;
    import mahjong.domain.set;
    auto wall = new MockWall(new Tile(Types.dragon, Dragons.red));
    auto player1 = new Player();
    player1.game = new Ingame(PlayerWinds.east);
    player1.drawTile(wall);
    auto player2 = new Player();
    player2.game = new Ingame(PlayerWinds.south);
    auto metagame = new Metagame([player1, player2], new DefaultBambooOpts);
    metagame.wall = new MockWall(new Tile(Types.ball, Numbers.one));
    auto mahjongData = MahjongData(player1, true, [new SevenPairsSet(player1.closedHand.tiles)]);
    auto transactions = [mahjongData].toTransactions(metagame);
    transactions.length.should.equal(2);
}

@("When a game is decided by a ron, only the discarding and the winning player have transactions")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    import mahjong.domain.set;
    auto player1 = new Player();
    player1.game = new Ingame(PlayerWinds.east);
    player1.closedHand.tiles = "🀃🀃🀃🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
    auto player2 = new Player();
    player2.game = new Ingame(PlayerWinds.south);
    auto player3 = new Player();
    player3.game = new Ingame(PlayerWinds.west);
    auto tile = new Tile(Types.dragon, Dragons.red);
    tile.isDrawnBy(player2);
    tile.isDiscarded;
    auto metagame = new Metagame([player1, player2, player3], new DefaultBambooOpts);
    metagame.wall = new MockWall(new Tile(Types.ball, Numbers.one));
    player1.ron(tile, metagame);
    auto mahjongData1 = MahjongData(player1, true, [new SevenPairsSet(player1.closedHand.tiles)]);
    auto transactions = [mahjongData1].toTransactions(metagame);
    transactions.length.should.equal(2);
}

@("In the case of a double ron, the losing player's transactions get combined")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    import mahjong.domain.set;
    auto player1 = new Player();
    player1.game = new Ingame(PlayerWinds.east);
    player1.closedHand.tiles = "🀃🀃🀃🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
    auto player2 = new Player();
    player2.game = new Ingame(PlayerWinds.south);
    auto player3 = new Player();
    player3.game = new Ingame(PlayerWinds.west);
    player3.closedHand.tiles = "🀃🀃🀃🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
    auto tile = new Tile(Types.dragon, Dragons.red);
    tile.isDrawnBy(player2);
    tile.isDiscarded;
    auto metagame = new Metagame([player1, player2, player3], new DefaultBambooOpts);
    metagame.wall = new MockWall(new Tile(Types.ball, Numbers.one));
    player1.ron(tile, metagame);
    player3.ron(tile, metagame);
    auto mahjongData1 = MahjongData(player1, true, [new SevenPairsSet(player1.closedHand.tiles)]);
    auto mahjongData2 = MahjongData(player3, true, [new SevenPairsSet(player3.closedHand.tiles)]);
    auto transactions = [mahjongData1, mahjongData2].toTransactions(metagame);
    transactions.length.should.equal(3);
}

private Transaction[] extractTransactions(const MahjongData data, const Metagame metagame)
{
    auto scoring = data.calculateScoring(metagame);
    auto payment = scoring.calculatePayment(data.player.isEast);
    Transaction[] transactions;
    if(data.isTsumo || data.isNagashiMangan)
    {
        foreach(player; metagame.otherPlayers(data.player))
        {
            auto amount = player.isEast ? -payment.east : -payment.nonEast;
            transactions ~= new Transaction(player, amount);
        }
    }
    else
    {
        auto payingPlayer = metagame.players.first!(p => data.player.lastTile.isOwnedBy(p));
        transactions ~= new Transaction(payingPlayer, -payment.ron);
    }
    transactions ~= new Transaction(data.player, payment.ron);
    return transactions;
}

private Transaction[] getRiichiTransactions(const Metagame metagame, const MahjongData[] mahjongData) pure
{
    if(metagame.amountOfRiichiSticks == 0) return null;
    if(mahjongData.length == 1)
    {
        auto player = mahjongData[0].player;
        return [new Transaction(player, metagame.amountOfRiichiSticks * metagame.riichiFare)];
    }
    return splitRiichiSticksPerPlayer(metagame, mahjongData);
}


unittest
{
    import fluent.asserts;
    auto metagame = new RiichiStickMetagame(0);
    auto transactions = getRiichiTransactions(metagame, [MahjongData()]);
    transactions.length.should.equal(0)
        .because("there are no riichi sticks");
}

unittest
{
    import fluent.asserts;
    auto winningPlayer = new Player;
    auto metagame = new RiichiStickMetagame(42);
    auto mahjongData = MahjongData(winningPlayer, true, null);
    auto transactions = getRiichiTransactions(metagame,[mahjongData]);
    transactions.length.should.equal(1);
    winningPlayer.shouldGet(42_000, transactions);
}

private Transaction[] splitRiichiSticksPerPlayer(const Metagame metagame, const MahjongData[] mahjongData) pure
{
    int[const(Player)] riichiSticksPerPlayer;
    int i = 1;
    foreach(player; mahjongData.map!(x => x.player).cycle)
    {
        if(int* sticks = player in riichiSticksPerPlayer)
        {
            (*sticks)++;
        }
        else
        {
            riichiSticksPerPlayer[player] = 1;
        }
        ++i;
        if(i > metagame.amountOfRiichiSticks) break;
    }
    return mahjongData
        .map!(md => new Transaction(md.player, riichiSticksPerPlayer[md.player] * metagame.riichiFare))
        .array;
}

unittest
{
    import fluent.asserts;
    auto player1 = new Player;
    auto player2 = new Player;
    auto metagame = new RiichiStickMetagame(42);
    auto mahjongData = [
        MahjongData(player1, true, null),
        MahjongData(player2, true, null)
    ];
    auto transactions = getRiichiTransactions(metagame, mahjongData);
    transactions.length.should.equal(2);
    player1.shouldGet(21_000, transactions);
    player2.shouldGet(21_000, transactions);
}

unittest
{
    import fluent.asserts;
    auto player1 = new Player;
    auto player2 = new Player;
    auto metagame = new RiichiStickMetagame(41);
    auto mahjongData = [
        MahjongData(player1, true, null),
        MahjongData(player2, true, null)
    ];
    auto transactions = getRiichiTransactions(metagame, mahjongData);
    transactions.length.should.equal(2);
    player1.shouldGet(21_000, transactions);
    player2.shouldGet(20_000, transactions);
}

Transaction[] calculateTenpaiTransactions(const Metagame metagame)
{
    const(Player)[] tenpaiPlayers;
    const(Player)[] nonTenpaiPlayers;
    foreach(player; metagame.players)
    {
        if(player.isTenpai)
        {
            tenpaiPlayers ~= player;
        }
        else
        {
            nonTenpaiPlayers ~= player;
        }
    }
    if(tenpaiPlayers.length == 0 || nonTenpaiPlayers.length == 0) return null;
    int total = (metagame.players.length.to!int-1) * metagame.riichiFare;
    return tenpaiPlayers.map!(p => new Transaction(p, total/tenpaiPlayers.length.to!int))
        .chain(nonTenpaiPlayers.map!(p => new Transaction(p, -total/nonTenpaiPlayers.length.to!int)))
        .array;
}

@("When no-one is tenpai, there shouldn't be any transactions")
unittest
{
    import fluent.asserts;
    auto metagame = new Metagame(
        [createNonTenpaiPlayer, createNonTenpaiPlayer, createNonTenpaiPlayer, createNonTenpaiPlayer], 
        new DefaultGameOpts);
    auto transactions = metagame.calculateTenpaiTransactions;
    transactions.length.should.equal(0);
}

@("If one player is tenpai, everyone should pay that player")
unittest
{
    import fluent.asserts;
    auto winner = createTenpaiPlayer;
    auto loser1 = createNonTenpaiPlayer;
    auto loser2 = createNonTenpaiPlayer;
    auto loser3 = createNonTenpaiPlayer;
    auto metagame = new Metagame(
        [winner, loser1, loser2, loser3], 
        new DefaultGameOpts);
    auto transactions = metagame.calculateTenpaiTransactions;
    transactions.length.should.equal(4);
    winner.shouldGet(3_000, transactions);
    loser1.shouldGet(-1_000, transactions);
    loser2.shouldGet(-1_000, transactions);
    loser3.shouldGet(-1_000, transactions);
}

@("If two players are tenpai, the penalty and gains are split")
unittest
{
    import fluent.asserts;
    auto winner1 = createTenpaiPlayer;
    auto winner2 = createTenpaiPlayer;
    auto loser1 = createNonTenpaiPlayer;
    auto loser2 = createNonTenpaiPlayer;
    auto metagame = new Metagame(
        [winner1, winner2, loser1, loser2], 
        new DefaultGameOpts);
    auto transactions = metagame.calculateTenpaiTransactions;
    transactions.length.should.equal(4);
    winner1.shouldGet(1_500, transactions);
    winner2.shouldGet(1_500, transactions);
    loser1.shouldGet(-1_500, transactions);
    loser2.shouldGet(-1_500, transactions);
}

@("If three players are tenpai, the last one is should pay them all")
unittest
{
    import fluent.asserts;
    auto winner1 = createTenpaiPlayer;
    auto winner2 = createTenpaiPlayer;
    auto winner3 = createTenpaiPlayer;
    auto loser = createNonTenpaiPlayer;
    auto metagame = new Metagame(
        [winner1, winner2, winner3, loser], 
        new DefaultGameOpts);
    auto transactions = metagame.calculateTenpaiTransactions;
    transactions.length.should.equal(4);
    winner1.shouldGet(1_000, transactions);
    winner2.shouldGet(1_000, transactions);
    winner3.shouldGet(1_000, transactions);
    loser.shouldGet(-3_000, transactions);
}

@("If everyone is tenpai, no transactions are generated")
unittest
{
    import fluent.asserts;
    auto winner1 = createTenpaiPlayer;
    auto winner2 = createTenpaiPlayer;
    auto winner3 = createTenpaiPlayer;
    auto winner4 = createTenpaiPlayer;
    auto metagame = new Metagame(
        [winner1, winner2, winner3, winner4], 
        new DefaultGameOpts);
    auto transactions = metagame.calculateTenpaiTransactions;
    transactions.length.should.equal(0);
}

private Transaction[] mergeTransactions(Transactions)(Transactions transactions) pure
    if(isInputRange!Transactions && is(ElementType!Transactions : Transaction))
{
    Transaction[const Player] mergedTransactions;
    foreach(transaction; transactions)
    {
        if(transaction.player in mergedTransactions)
        {
            mergedTransactions[transaction.player] = mergedTransactions[transaction.player] + transaction;
        }
        else
        {
            mergedTransactions[transaction.player] = transaction;
        }
    }
    return mergedTransactions.values;
}

class Transaction
{
    this(const Player player, const int amount) pure
    {
        this.player = player;
        this.amount = amount;
    }

    const Player player;
    const int amount;

    Transaction opBinary(string op)(Transaction rhs) pure
    in
    {
        assert(player is rhs.player, "Cannot sum the transactions of two players");
    }
    body
    {
        static if(op == "+") return new Transaction(player, amount + rhs.amount);
        else static if(op == "-") return new Transaction(player, amount - rhs.amount);
        else static assert(false, "Operator " ~ op ~ " not supported");
    }

    bool isPayment() pure const @property
    {
        return amount < 0;
    }
}

unittest
{
    auto player = new Player();
    auto transactionA = new Transaction(player, 1234);
    auto transactionB = new Transaction(player, 5678);
    auto sumOfTransactions = transactionA + transactionB;
    assert(sumOfTransactions.amount == 6912, "The transactions are summed together.");
    auto differenceOfTransactions = transactionB - transactionA;
    assert(differenceOfTransactions.amount == 4444, "The transactions should be subtracted.");
}

unittest
{
    import std.exception;
    import core.exception;
    auto player = new Player();
    auto player2 = new Player();
    auto transactionA = new Transaction(player, 123);
    auto transactionB = new Transaction(player2, 456);
    assertThrown!AssertError(transactionA + transactionB, "Summing transactions of two different player is not allowed.");
}

private enum prelimitScores = initializePreLimitPayments();
private enum limitScores = initializeLimitPayments();

private struct RawPayment
{
    const int east;
    const int nonEast;
}

private RawPayment[size_t][size_t] initializePreLimitPayments()
{
    RawPayment[size_t][size_t] prelimitPayments;
    prelimitPayments[1] = [
        30: RawPayment( 500, 300),
        40: RawPayment( 700, 400),
        50: RawPayment( 800, 400),
        60: RawPayment(1000, 500),
        70: RawPayment(1200, 600)
    ];
    prelimitPayments[2] = [
        20: RawPayment( 700, 400),
        25: RawPayment( 800, 400),
        30: RawPayment(1000, 500),
        40: RawPayment(1300, 700),
        50: RawPayment(1600, 800),
        60: RawPayment(2000,1000),
        70: RawPayment(2300,1200)
    ];
    prelimitPayments[3] = [
        20: RawPayment(1300, 700),
        25: RawPayment(1600, 800),
        30: RawPayment(2000,1000),
        40: RawPayment(2600,1300),
        50: RawPayment(3200,1600),
        60: RawPayment(3900,2000),
        70: RawPayment(4000,2000)
    ];
    prelimitPayments[4] = [
        20: RawPayment(2600,1300),
        25: RawPayment(3200,1600),
        30: RawPayment(3900,2000),
        40: RawPayment(4000,2000),
        50: RawPayment(4000,2000),
        60: RawPayment(4000,2000),
        70: RawPayment(4000,2000)
    ];

    return prelimitPayments;
}

private RawPayment[size_t] initializeLimitPayments()
{
    return [
        5: RawPayment( 4000, 2000),
        6: RawPayment( 6000, 3000),
        8: RawPayment( 8000, 4000),
        11:RawPayment(12000, 6000),
        13:RawPayment(16000, 8000)
    ];
}

private RawPayment findRawPaymentForLimitHands(size_t amountOfFan)
{
    return limitScores.byKeyValue
        .filter!(kv => kv.key <= amountOfFan).array
            .sort!((a,b) => a.key < b.key)
            .array.back.value;
}

unittest
{
    assert(limitScores[5] == findRawPaymentForLimitHands(5), "With five fan, the payment for five fan should be returned");
    assert(limitScores[6] == findRawPaymentForLimitHands(6), "With six fan, the payment for six fan should be returned");
    assert(limitScores[6] == findRawPaymentForLimitHands(7), "With seven fan, the payment for six fan should be returned");
    assert(limitScores[8] == findRawPaymentForLimitHands(8), "With eight fan, the payment for eight fan should be returned");
    assert(limitScores[8] == findRawPaymentForLimitHands(9), "With nine fan, the payment for eight fan should be returned");
    assert(limitScores[8] == findRawPaymentForLimitHands(10), "With ten fan, the payment for eight fan should be returned");
    assert(limitScores[11] == findRawPaymentForLimitHands(11), "With eleven fan, the payment for eleven fan should be returned");
    assert(limitScores[11] == findRawPaymentForLimitHands(12), "With twelve fan, the payment for eleven fan should be returned");
    assert(limitScores[13] == findRawPaymentForLimitHands(13), "With thirteen fan, the payment for a yakuman should be returned");
    assert(limitScores[13] == findRawPaymentForLimitHands(25), "With over thirteen fan, the payment for a yakuman should be returned");
}

private size_t roundMiniPoints(size_t miniPoints)
{
    if(miniPoints == 25) return 25;
    return ceil(miniPoints/10.).to!size_t*10;
}

unittest
{
    assert(20 == roundMiniPoints(20), "When the number is dividable by 10, the rounded minipoints don't change");
    assert(25 == roundMiniPoints(25), "25 is the magic number that should stay itself.");
    assert(30 == roundMiniPoints(22), "22 should be rounded up to 30.");
    assert(30 == roundMiniPoints(30), "When the number is dividable by 10, the rounded minipoints don't change");
}

private size_t countAmountOfDoras(const MahjongData mahjongResult, const Wall wall) pure
{
    auto doraIndicators = wall.doraIndicators;
    size_t doras = 0;
    foreach(doraIndicator; doraIndicators)
    {
        auto dora = doraIndicator.getDoraValue;
        doras += mahjongResult.tiles.count!(tile => dora.hasEqualValue(tile));
    }
    return doras;
}

unittest
{
    import mahjong.domain.set;
    auto doraIndicator = new Tile(Types.bamboo, Numbers.eight);
    auto mahjongResult = MahjongData(null, false, 
        [new ChiSet([
                    new Tile(Types.bamboo, Numbers.six),
                    new Tile(Types.bamboo, Numbers.seven),
                    new Tile(Types.bamboo, Numbers.eight)
                ])]);
    auto doras = mahjongResult.countAmountOfDoras(new DoraIndicatorWall([doraIndicator]));
    assert(doras == 0, "No doras should be found");
}

unittest
{
    import mahjong.domain.set;
    auto doraIndicator = new Tile(Types.bamboo, Numbers.five);
    auto mahjongResult = MahjongData(null, false, 
        [new ChiSet([
                    new Tile(Types.bamboo, Numbers.six),
                    new Tile(Types.bamboo, Numbers.seven),
                    new Tile(Types.bamboo, Numbers.eight)
                ])]);
    auto doras = mahjongResult.countAmountOfDoras(new DoraIndicatorWall([doraIndicator]));
    assert(doras == 1, "Only one dora should be found");
}

unittest
{
    import mahjong.domain.set;
    auto doraIndicator = new Tile(Types.bamboo, Numbers.five);
    auto mahjongResult = MahjongData(null, false, 
        [new PonSet([
                    new Tile(Types.bamboo, Numbers.six),
                    new Tile(Types.bamboo, Numbers.six),
                    new Tile(Types.bamboo, Numbers.six)
                ])]);
    auto doras = mahjongResult.countAmountOfDoras(
        new DoraIndicatorWall([doraIndicator]));
    assert(doras == 3, "All three tiles are doras");
}

unittest
{
    import mahjong.domain.set;
    auto doraIndicator = new Tile(Types.bamboo, Numbers.five);
    auto mahjongResult = MahjongData(null, false, 
        [new ChiSet([
                    new Tile(Types.bamboo, Numbers.six),
                    new Tile(Types.bamboo, Numbers.seven),
                    new Tile(Types.bamboo, Numbers.eight)
                ])]);
    auto doras = mahjongResult.countAmountOfDoras(
        new DoraIndicatorWall([doraIndicator, doraIndicator]));
    assert(doras == 2, "When the indicator is in there twice, the doras count double");
}

private const(ComparativeTile) getDoraValue(const Tile doraIndicator) pure
{
    return ComparativeTile(doraIndicator.type,
        (doraIndicator.value + 1) % doraIndicator.type.amountOfTiles);
}

unittest
{
    auto doraIndicator = new Tile(Types.dragon, Dragons.green);
    auto dora = doraIndicator.getDoraValue;
    assert(ComparativeTile(Types.dragon, Dragons.red) == dora, "Green dragon points to red dragon as a dora");
}

unittest
{
    auto doraIndicator = new Tile(Types.dragon, Dragons.white);
    auto dora = doraIndicator.getDoraValue;
    assert(ComparativeTile(Types.dragon, Dragons.green) == dora, "White dragon points to green dragon as a dora");
}

unittest
{
    auto doraIndicator = new Tile(Types.wind, Winds.south);
    auto dora = doraIndicator.getDoraValue;
    assert(ComparativeTile(Types.wind, Winds.west) == dora, "West should be a dora");
}

unittest
{
    auto doraIndicator = new Tile(Types.wind, Winds.north);
    auto dora = doraIndicator.getDoraValue;
    assert(ComparativeTile(Types.wind, Winds.east) == dora, "East should be a dora");
}

unittest
{
    auto doraIndicator = new Tile(Types.bamboo, Numbers.five);
    auto dora = doraIndicator.getDoraValue;
    assert(ComparativeTile(Types.bamboo, Numbers.six) == dora, "Bamboo six should be a dora");
}

unittest
{
    auto doraIndicator = new Tile(Types.bamboo, Numbers.nine);
    auto dora = doraIndicator.getDoraValue;
    assert(ComparativeTile(Types.bamboo, Numbers.one) == dora, "Bamboo one should be a dora");
}

enum limit_hands {mangan = 5, haneman = 6, baiman = 8, 
    sanbaiman = 11, yakuman = 13, double_yakuman = 26, 
    triple_yakuman = 39, quadra_yakuman = 52, penta_yakuman = 65, 
    hexa_yakuman = 78, septa_yakuman = 91};

version(unittest)
{
    class RiichiStickMetagame : Metagame
    {
        this(int amountOfRiichiSticks)
        {
            super([new Player()], new DefaultGameOpts);
            _amountOfRiichiSticks = amountOfRiichiSticks;
        }
        private int _amountOfRiichiSticks;

        override int amountOfRiichiSticks() pure const 
        {
            return _amountOfRiichiSticks;
        }
    }

    private Player createNonTenpaiPlayer()
    {
        auto player = new Player;
        player.game = new Ingame(PlayerWinds.east, "🀇🀇🀇🀈🀈🀈🀈🀌🀌🀊🀊🀆🀆"d);
        return player;
    }

    private Player createTenpaiPlayer()
    {
        auto player = new Player;
        player.game = new Ingame(PlayerWinds.east, "🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
        return player;
    }

    private void shouldGet(Player player, int amount, Transaction[] transactions)
    {
        import fluent.asserts;
        auto result = transactions.find!(tx => tx.player == player);
        if(amount == 0)
        {
            if(result.empty) return; 
            // Not having a transaction also counts as not getting anything
        }
        result.empty.should.equal(false);
        result.front.amount.should.equal(amount);
    }

    class DoraIndicatorWall : Wall
    {
        this(const(Tile)[] doraIndicators)
        {
            super(new DefaultGameOpts);
            _doraIndicators = doraIndicators;
        }
        private const(Tile)[] _doraIndicators;

        override const(Tile)[] doraIndicators() pure const @property
        {
            return _doraIndicators;
        }
    }
}
