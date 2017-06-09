module mahjong.engine.scoring;

import std.algorithm;
import std.array;
import std.conv;
import std.math;
import mahjong.domain.enums;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.mahjong;
import mahjong.engine.opts;
import mahjong.engine.yaku;
import mahjong.share.range;

Scoring calculateScoring(const MahjongResult mahjongResult, const Ingame player, const Metagame metagame)
{
	auto yaku = mahjongResult.determineYaku(player, metagame);
	auto miniPoints = mahjongResult.miniPoints;
	auto amountOfDoras = mahjongResult.countAmountOfDoras(metagame.wall);
	return new Scoring(yaku, miniPoints, amountOfDoras, player.isClosedHand);
}

class Scoring
{
	private this(const(Yaku)[] yakus, size_t miniPoints, 
		size_t amountOfDoras, bool isClosedHand)
	{
		this.yakus = yakus;
		this.miniPoints = miniPoints;
		this.amountOfDoras = amountOfDoras;
		_isClosedHand = isClosedHand;
	}

	const(Yaku)[] yakus;
	const size_t miniPoints;
	const size_t amountOfDoras;
	private bool _isClosedHand;

	Payment calculatePayment(bool isWinningPlayerEast)
	{
		auto fan = yakus.sum!(yaku => yaku.convertToFan(_isClosedHand));
		return new Payment(0, 0, true);
	}

	private Payment calculatePaymentForLimitHands(size_t amountOfFan, bool isWinningPlayerEast)
	{
		auto rawPayment = findRawPaymentForLimitHands(amountOfFan);
		return new Payment(rawPayment.east, rawPayment.nonEast, isWinningPlayerEast);
	}

	private Payment calculatePaymentForNonLimitHands(size_t amountOfFan, bool isWinningPlayerEast)
	{
		auto rawPayment = prelimitScores[miniPoints][amountOfFan];
		return new Payment(rawPayment.east, rawPayment.nonEast, isWinningPlayerEast);
	}
}

class Payment
{
	this(size_t east, size_t nonEast, bool isWinningPlayerEast)
	{
		this.east = east;
		// If the winning player is east, all non-easy players pay the east level.
		this.nonEast = isWinningPlayerEast ? east : nonEast;
	}

	const size_t east;
	const size_t nonEast;
	size_t ron() @property
	{
		// Sum the payments of every player.
		return east + (gameOpts.amountOfPlayers - 2) * nonEast;
	}
}

unittest
{
	gameOpts = new DefaultGameOpts;
	auto payment = new Payment(2000, 1000, false);
	assert(payment.east == 2000, "The east value should have been initialized at 2000");
	assert(payment.nonEast == 1000, "The non-east value should have been initialized at the base value of 1000");
	assert(payment.ron == 4000, "The ron payment should be east + 2*non-east");
}

unittest
{
	gameOpts = new DefaultGameOpts;
	auto payment = new Payment(2000, 1000, true);
	assert(payment.east == 2000, "The east value should again have been initialized at 2000");
	assert(payment.nonEast == 2000, "Because east won, the non-east players also pay 2000");
	assert(payment.ron == 6000, "The ron payment should be 3*east");
}

unittest
{
	gameOpts = new BambooOpts;
	auto payment = new Payment(2000, 1000, false);
	assert(payment.east == 2000, "The east value should have been initialized at 2000");
	// Non east is not actually relevant.
	assert(payment.ron == 2000, "The ron payment should be simply east, because there are no other players.");
}

unittest
{
	gameOpts = new BambooOpts;
	auto payment = new Payment(2000, 1000, true);
	assert(payment.east == 2000, "The east value should have been initialized at 2000 and is invariant of who won.");
	// Non east is not actually relevant.
	assert(payment.ron == 2000, "The ron payment should be simply east, because there are no other players and is invariant of who won.");
}

private enum prelimitScores = initializePreLimitPayments();
private enum limitScores = initializeLimitPayments();

private struct RawPayment
{
	const size_t east;
	const size_t nonEast;
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

private size_t countAmountOfDoras(const MahjongResult mahjongResult, const Wall wall)
{
	auto doraIndicators = wall.doraIndicators;
	size_t doras = 0;
	return doras;
}

private const(ComparativeTile) getDoraValue(const Tile doraIndicator)
{
	return ComparativeTile(doraIndicator.type,
		(doraIndicator.value + 1) % doraIndicator.type.amountOfTiles);
}

enum limit_hands {mangan = 5, haneman = 6, baiman = 8, 
	sanbaiman = 11, yakuman = 13, double_yakuman = 26, 
	triple_yakuman = 39, quadra_yakuman = 52, penta_yakuman = 65, 
	hexa_yakuman = 78, septa_yakuman = 91};