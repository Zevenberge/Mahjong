module mahjong.domain.mahjong;

import std.experimental.logger;
import std.algorithm;
import std.array;
import std.conv;
import std.typecons;

import mahjong.domain.analysis;
import mahjong.domain.closedhand;
import mahjong.domain.enums;
import mahjong.domain.openhand;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.result;
import mahjong.domain.set;
import mahjong.domain.tile;
import mahjong.util.collections : allocate, NoGcArray;
import mahjong.util.optional;
import mahjong.util.range;

MahjongResult scanHandForMahjong(const Ingame player) pure
{
	return scanHandForMahjong(player.closedHand.tiles, player.openHand.sets);
}

MahjongResult scanHandForMahjong(const Ingame player, const Tile discard) pure
{
	return scanHandForMahjong(player.closedHand.tiles ~ discard, player.openHand.sets);
}

@("Does an open pon count towards a mahjong")
unittest
{
	import mahjong.domain.creation;

	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto openHand = new OpenHand;
	openHand.addPon("🀃🀃🀃"d.convertToTiles);
	auto ingame = new Ingame(PlayerWinds.south);
	ingame.closedHand = closedHand;
	ingame.openHand = openHand;
	assert(scanHandForMahjong(ingame).isMahjong, "An open pon should count towards mahjong");
}

@("Does an open chi count towards a mahjong")
unittest
{
	import mahjong.domain.creation;

	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto openHand = new OpenHand;
	openHand.addChi("🀓🀔🀕"d.convertToTiles);
	auto ingame = new Ingame(PlayerWinds.east);
	ingame.closedHand = closedHand;
	ingame.openHand = openHand;
	assert(scanHandForMahjong(ingame).isMahjong, "An open chi should count towards mahjong");
}

bool isMahjong(const Ingame player) pure @nogc nothrow
{
	return scanHandForMahjong!(No.includeSets)(player.closedHand.tiles, player.openHand.sets);
}

@("Can I can a player for mahjong")
unittest
{
	import fluent.asserts;
	auto ingame = new Ingame(PlayerWinds.east, "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡🀓🀓🀓"d);
	ingame.isMahjong.should.equal(true);
}

@("If a player is not mahjong, we don't get a false positive")
unittest
{
	import fluent.asserts;
	auto ingame = new Ingame(PlayerWinds.east, "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡🀓🀓🀔"d);
	ingame.isMahjong.should.equal(false);
}

private auto scanHandForMahjong(Flag!("includeSets") includeSets = Yes.includeSets)
	(const(Tile)[] closedHand, const(Set[]) openSets) pure nothrow
in(closedHand.length > 0)
out(; closedHand.length > 0)
{ /*
	   See if the current hand is a legit mahjong hand.
	   */
	//auto sortedHand = sortHand(hand);
	auto hand = closedHand.asHand;
	hand.sort!byTypeValueAsc;
	// Run a dedicated scan for thirteen orphans
	if (hand.length == 14)
	{
		if (isThirteenOrphans(hand))
		{
			static if(includeSets == Yes.includeSets)
			{
				return MahjongResult(true, [thirteenOrphans(closedHand)]);
			}
			else
			{
				return true;
			}
		}
	}

	auto progress = Progress(hand, openSets);
	scanRegularMahjong(progress);

	if (hand.length == 14 && !progress.isMahjong)
	{ // If we don't have a mahjong using normal hands, we check whether we have seven pairs
		if (isSevenPairs(hand))
		{
			static if(includeSets == Yes.includeSets)
			{
				return MahjongResult(true, [sevenPairs(closedHand)]);
			}
			else
			{
				return true;
			}
		}
	}

	static if(includeSets == No.includeSets)
	{
		return progress.isMahjong;
	}
	else
	{
		const(Set)[] sets;
		sets ~= progress.pons.map!(x => pon(x.allocate)).array;
		sets ~= progress.chis.map!(x => chi(x.allocate)).array;
		sets ~= progress.pairs.map!(x => pair(x.allocate)).array;

		auto result = MahjongResult(progress.isMahjong, sets);
		return result;
	}
}

private bool isSevenPairs(const ref Hand hand) pure @nogc nothrow
{
	if (hand.length != 14)
		return false;
	for (int i = 0; i < 7; ++i)
	{
		if (hand.length > 2 * i + 2)
		{ // Check if no two pairs are the same, only if the hand size allows it.
			if (hand[2 * i].hasEqualValue(hand[2 * i + 2]))
			{
				return false;
			} // Return if we have three identical tiles.
		}
		if (!hand[2 * i].hasEqualValue(hand[2 * i + 1]))
		{ // Check whether is is a pair.
			return false;
		} // If it is no pair, it is no seven pairs hand.
	}
	return true;
}

private bool isThirteenOrphans(const ref Hand hand) pure @nogc nothrow
{

	if (hand.length != 14)
		return false;
	int pairs = 0;

	for (int i = 0; i < 13; ++i)
	{
		ComparativeTile honour;

		switch (i)
		{
		case 0: .. case 3: // Winds
			honour = ComparativeTile(Types.wind, i);
			break;
		case 4: .. case 6: // Dragons
			honour = ComparativeTile(Types.dragon, i % (Winds.max + 1));
			break;
		case 7: // Characters
			honour = ComparativeTile(Types.character, Numbers.one);
			break;
		case 8: // Characters
			honour = ComparativeTile(Types.character, Numbers.nine);
			break;
		case 9: // Bamboos
			honour = ComparativeTile(Types.bamboo, Numbers.one);
			break;
		case 10: // Bamboos
			honour = ComparativeTile(Types.bamboo, Numbers.nine);
			break;
		case 11: // Balls
			honour = ComparativeTile(Types.ball, Numbers.one);
			break;
		case 12: // Balls
			honour = ComparativeTile(Types.ball, Numbers.nine);
			break;
		default:
			assert(false);
		}
		if (!honour.hasEqualValue(hand[i + pairs])) //If the tile is not the honour we are looking for
		{
			return false;
		}
		if ((i + pairs + 1) < hand.length)
		{
			if (hand[i + pairs].hasEqualValue(hand[i + pairs + 1])) // If we have a pair
			{
				++pairs;
				if (pairs > 1)
				{
					return false;
				} // If we have more than one pair, it is not thirteen orphans.
			}
		}
	}
	/*
	 When the code arrives at this point, we have confirmed that the hand has each of the thirteen orphans in it. The final check is whether the hand also has the pair.
	 */

	return pairs == 1;
}

private struct Progress
{
	this(const ref Hand hand, const(Set[]) initialSets) pure @nogc nothrow
	{
		import mahjong.util.collections : array;
		this.hand = hand;
		foreach (set; initialSets)
		{
			if (set.isPon)
				pons ~= set.tiles.array!4;
			if (set.isChi)
				chis ~= set.tiles.array!4;
			// No pair because a pair cannot be open.
		}
	}

	alias CombiArray = NoGcArray!(4, const Combi);

	Hand hand;
	CombiArray pairs;
	CombiArray pons;
	CombiArray chis;

	void convertToPair(ref const Combi set) pure @nogc nothrow
	{
		pairs ~= set;
	}

	void convertToPon(ref const Combi set) pure @nogc nothrow
	{
		pons ~= set;
	}

	void convertToChi(ref const Combi set) pure @nogc nothrow
	{
		chis ~= set;
	}

	void subtractPair() pure @nogc nothrow
	{
		auto pair = pairs[$ - 1];
		recoverTiles(pair);
		pairs.removeAt(pairs.length-1);
	}

	void subtractPon() pure @nogc nothrow
	{
		auto pon = pons[$ - 1];
		recoverTiles(pon);
		pons.removeAt(pons.length-1);
	}

	void subtractChi() pure @nogc nothrow
	{
		auto chi = chis[$ - 1];
		recoverTiles(chi);
		chis.removeAt(chis.length-1);
	}

	private void recoverTiles(ref const Combi tiles) pure @nogc nothrow
	{
		foreach(i; 0 .. tiles.length)
		{
			hand ~= tiles[i];
		}
		hand.sort!byTypeValueAsc;
	}

	bool isMahjong() @property pure const @nogc nothrow
	{
		return pairs.length == 1 && pons.length + chis.length == 4;
	}
}

private void scanRegularMahjong(ref Progress progress) pure @nogc nothrow
{
	/*
	   It first checks if the first two tiles form a pair (max. 1). 
	   Then it checks if the first three tiles form a pon. If it fails, it returns a false.

	   pairs --- pons  --- chis                <- finds a pair
	   +- pons  --- chis                <- finds a pon
	   +- pons  -- chis       <- finds nothing and returns to the previous layer, in which it can still find a chi.

	*/
	if (progress.pairs.length < 1)
	{ // Check if there is a pair, but only if there is not yet a pair.
		attemptToResolvePair(progress);
		if (progress.isMahjong)
			return;
	}
	attemptToResolvePon(progress);
	if (progress.isMahjong)
		return;
	return attemptToResolveChi(progress);
}

private void attemptToResolvePair(ref Progress progress) pure @nogc nothrow
{
	if (progress.hand.length < 2)
		return;
	auto pair = seperatePair(progress.hand);
	if (!pair.isSeperated)
		return;
	progress.convertToPair(pair.get);
	scanRegularMahjong(progress);
	if (!progress.isMahjong)
	{
		progress.subtractPair;
	}
}

private void attemptToResolvePon(ref Progress progress) pure @nogc nothrow
{
	if (progress.hand.length < 3)
		return;
	auto pon = seperatePon(progress.hand);
	if (!pon.isSeperated)
		return;
	progress.convertToPon(pon.get);
	scanRegularMahjong(progress);
	if (!progress.isMahjong)
	{
		progress.subtractPon;
	}
}

private void attemptToResolveChi(ref Progress progress) pure @nogc nothrow
{
	if (progress.hand.length < 3)
		return;
	auto chi = seperateChi(progress.hand);
	if (!chi.isSeperated)
		return;
	progress.convertToChi(chi.get);
	scanRegularMahjong(progress);
	if (!progress.isMahjong)
	{
		progress.subtractChi;
	}
}

@("Are the example hands mahjong hands?")
unittest  // Check whether the example hands are seen as mahjong hands.
{
	import std.stdio;
	import std.path;
	import std.string;

	void testHands(string filename, const bool isHand)
	{
		writeln("Looking for ", filename.asAbsolutePath);
		auto output = readLines(filename);
		foreach (line; output)
		{
			assert(line.length == 14, "A complete hand is 14 tiles");
			auto hand = convertToTiles(line);
			bool isMahjong;
			isMahjong = scanHandForMahjong(hand, null).isMahjong;
			assert(isHand == isMahjong, "For %s, the mahjong should be %s".format(line, isHand));
			write("The mahjong is ", isMahjong, ".  ");
			writeln(line);
		}
		writeln();

	}

	writeln("Checking the example hands...");
	testHands("test/nine_gates", true);
	testHands("test/example_hands", true);
	testHands("test/unlegit_hands", false);
	writeln(" The function reads the example hands correctly.");
}

version (unittest)
{
	import std.file;
	import std.range;
	import std.stdio;
	import std.string;
	import mahjong.domain.creation;

	/// Read the given file into dstring lines
	dstring[] readLines(string filename)
	{
		if (exists(filename))
		{
			dstring[] output;
			auto file = File(filename, "r");
			while (!file.eof())
			{
				string line = chomp(file.readln());
				dchar[] dline;
				foreach (face; stride(line, 1))
				{
					dline ~= face;
				}
				output ~= dline.to!dstring;
			}
			return output;
		}
		else
		{
			throw new Exception("The file does not exist.");
		}
	}
}

bool isPlayerTenpai(const(Tile)[] closedHand, const OpenHand openHand)
{
	import mahjong.domain.creation : allTiles;

	return allTiles.any!(tile => scanHandForMahjong(closedHand ~ tile, openHand.sets).isMahjong);
}

@("Is the player tenpai")
unittest
{
	import fluent.asserts;
	import mahjong.domain.creation;

	auto tenpaiHand = "🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	auto emptyOpenHand = new OpenHand;
	isPlayerTenpai(tenpaiHand, emptyOpenHand).should.equal(true);
	auto noTenpaiHand = "🀇🀇🀇🀈🀈🀈🀈🀌🀌🀊🀊🀆🀆"d.convertToTiles;
	isPlayerTenpai(noTenpaiHand, emptyOpenHand).should.equal(false);
}

@("If the player only needs one more tile, they are tenpai")
unittest
{
	import fluent.asserts;
	import mahjong.domain.creation;

	auto tenpaiHand = "🀀🀁🀂🀃🀄🀆🀆🀇🀏🀐🀘🀙🀡"d.convertToTiles;
	auto emptyOpenHand = new OpenHand;
	isPlayerTenpai(tenpaiHand, emptyOpenHand).should.equal(true);
}

@("A tenpai check should be efficient")
unittest
{
	import core.time;
	import fluent.asserts;
	import mahjong.domain.creation;

	auto tenpaiHand = "🀀🀁🀂🀃🀄🀆🀆🀇🀏🀐🀘🀙🀡"d.convertToTiles;
	auto emptyOpenHand = new OpenHand;
	({isPlayerTenpai(tenpaiHand, emptyOpenHand);}).should.haveExecutionTime.lessThan(1.msecs);
}

auto constructMahjongData(Metagame metagame)
in
{
	assert(metagame.players.any!(p => p.isMahjong) ||
		(metagame.isExhaustiveDraw && metagame.players.any!(p => p.isNagashiMangan)), 
		"Can only construct mahjong data if at least one of the players is eligible for mahjong");
}
do
{
	auto regularMahjong = metagame.playersByTurnOrder
		.map!(p => p.calculateMahjongData())
		.filter!(data => data.result.isMahjong)
		.array;
	if(regularMahjong.length != 0) return regularMahjong;
	return metagame.playersByTurnOrder
		.map!(p => p.calculateNagashiMangan)
		.filter!(data => data.result.isMahjong)
		.array;
}

@("Are only winning players included in the data")
unittest
{
	import std.range;
	import fluent.asserts;
	import mahjong.domain.opts;

	auto winningGame = new Ingame(PlayerWinds.east,
			"🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
	auto losingGame = new Ingame(PlayerWinds.west,
			"🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
	auto player1 = new Player;
	auto player2 = new Player;
	auto player3 = new Player;
	auto player4 = new Player;
	auto metagame = new Metagame([player1, player2, player3, player4], new DefaultGameOpts);
	player1.game = winningGame;
	player2.game = losingGame;
	player3.game = winningGame;
	player4.game = losingGame;
	metagame.currentPlayer = player2;
	auto mahjongData = metagame.constructMahjongData.array;
	mahjongData.length.should.equal(2);
	mahjongData[0].player.should.equal(player3);
	mahjongData[1].player.should.equal(player1);
}

@("When I claim the last tile before exhaustive draw, I should get my regular data")
unittest
{
	import fluent.asserts;
	import mahjong.domain.wall;
	import mahjong.domain.opts;

	auto winningGame = new Ingame(PlayerWinds.east,
			"🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
	auto losingGame = new Ingame(PlayerWinds.west,
			"🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
	auto player1 = new Player;
	auto player2 = new Player;
	auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
	metagame.wall = new MockWall(true);
	player1.game = winningGame;
	player1.isNotNagashiMangan;
	player2.game = losingGame;
	player2.isNotNagashiMangan;
	auto mahjongData = metagame.constructMahjongData.array;
	mahjongData.length.should.equal(1);
	mahjongData[0].player.should.equal(player1);
}

@("If a regular mahjong happens while someone has nagashi mangan, the regular mahjong has preference")
unittest
{
	import fluent.asserts;
	import mahjong.domain.wall;
	import mahjong.domain.opts;

	auto winningGame = new Ingame(PlayerWinds.east,
			"🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
	auto losingGame = new Ingame(PlayerWinds.west,
			"🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
	auto player1 = new Player;
	auto player2 = new Player;
	auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
	metagame.wall = new MockWall(true);
	player1.game = winningGame;
	player1.isNotNagashiMangan;
	player2.game = losingGame;
	//player2.isNagashiMangan;
	auto mahjongData = metagame.constructMahjongData.array;
	mahjongData.length.should.equal(1);
	mahjongData[0].player.should.equal(player1);
}

private MahjongData calculateMahjongData(const Player player)
{
	auto mahjongResult = scanHandForMahjong(player);
	return MahjongData(player, mahjongResult);
}

@("If a player is mahjong, it should be concluded as such")
unittest
{
	import fluent.asserts;

	auto winningGame = new Ingame(PlayerWinds.east,
			"🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
	auto player = new Player;
	player.game = winningGame;
	auto result = player.calculateMahjongData();
	result.isMahjong.should.equal(true);
}

@("If a player is not mahjong, it should also be concluded as such")
unittest
{
	import fluent.asserts;

	auto losingGame = new Ingame(PlayerWinds.west,
			"🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
	auto player = new Player;
	player.game = losingGame;
	auto result = player.calculateMahjongData();
	result.isMahjong.should.equal(false);
}

private MahjongData calculateNagashiMangan(const Player player)
{
	return MahjongData(player, MahjongResult(player.isNagashiMangan, [nagashiMangan()]));
}

@("If the game is an exhaustive draw, a nagashi mangan is counted as a mahjong")
unittest
{
	import fluent.asserts;

	auto losingGame = new Ingame(PlayerWinds.west,
			"🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
	auto player = new Player;
	player.game = losingGame;
	auto result = player.calculateNagashiMangan;
	result.isMahjong.should.equal(true);
	result.isNagashiMangan.should.equal(true);
}

struct MahjongData
{
	this(const Player player, bool isMahjong, const(Set)[] sets)
	{
		this(player, MahjongResult(isMahjong, sets));
	}

	this(const Player player, const MahjongResult result)
	{
		this.player = player;
		this.result = result;
	}

	const(Player) player;
	const(MahjongResult) result;
	alias result this;
	bool isWinningPlayerEast() @property pure const
	{
		return player.isEast;
	}

	size_t calculateMiniPoints(PlayerWinds leadingWind) const
	{
		alias isSevenPairHand = mahjong.domain.result.isSevenPairs;
		alias isThirteenOrphansHand = mahjong.domain.result.isThirteenOrphans;
		if (result.isNagashiMangan || isThirteenOrphansHand(result))
			return 30;
		if (isSevenPairHand(result))
			return 25;
		auto miniPointsFromWinning = player.isClosedHand && !isTsumo ? 30 : 20;
		auto miniPointsFromSets = result.calculateMiniPoints(player.wind.to!PlayerWinds,
				leadingWind);
		auto miniPointsFromWait = result.isTwoSidedWait(player.lastTile)
			|| result.isPonWait(player.lastTile) ? 0 : 2;
		size_t miniPointsFromDrawing = 0;
		if (miniPointsFromSets + miniPointsFromWait != 0)
		{
			miniPointsFromDrawing = isTsumo ? 2 : 0;
		}
		return miniPointsFromSets + miniPointsFromWinning + miniPointsFromWait
			+ miniPointsFromDrawing;
	}

	@("A self draw on a concealed hand with only chis result in 20 minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;

		auto wall = new MockWall(new Tile(Types.ball, Numbers.one));
		auto player = new Player("🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀠🀡"d);
		player.drawTile(wall);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(20);
	}

	@("A ron on a concealed hand is worth 30 points")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀠🀡"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(30);
	}

	@("Pons get awarded minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀚🀛🀜🀜🀝🀝🀞🀞🀟🀟🀠🀠🀠"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(34);
	}

	@("A pair of own winds is worth 2 points")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀁🀁🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀡"d,
				PlayerWinds.south);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(32);
	}

	@("A pair of leading winds is worth 2 points")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀀🀀🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀡"d,
				PlayerWinds.south);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(32);
	}

	@("A pair that is both leading and own wind is still worth 2 points")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀀🀀🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀡"d,
				PlayerWinds.east);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(32);
	}

	@("A pair of dragons is worth 2 points")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀆🀆🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀡"d,
				PlayerWinds.east);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(32);
	}

	@("A ron on an open hand is worth 20 points")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.chi;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀠"d);
		auto chiTile = new Tile(Types.ball, Numbers.nine);
		chiTile.isNotOwn;
		chiTile.isDiscarded;
		player.chi(chiTile, ChiCandidate(player.closedHand.tiles[$ - 4],
				player.closedHand.tiles[$ - 3]));
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(20);
	}

	@("A seven pairs hand is worth 25 points")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀈🀈🀍🀍🀑🀑🀖🀖🀙🀚🀚🀟🀟"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(25);
	}

	@("A closed seven pairs hand is also worth 25 points")
	unittest
	{
		import fluent.asserts;

		auto player = new Player("🀈🀈🀍🀍🀑🀑🀖🀖🀙🀙🀚🀚🀟🀟"d);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(25);
	}

	@("Pair minipoints are ignored in a seven pairs hand.")
	unittest
	{
		import fluent.asserts;

		auto player = new Player("🀀🀀🀆🀆🀈🀈🀍🀍🀑🀑🀖🀖🀙🀙"d);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(25);
	}

	@("A closed wait is worth two extra minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.two);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀙🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀠🀡"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(32);
	}

	@("An edge wait is worth two extra minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.three);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀙🀚🀜🀜🀝🀝🀞🀞🀟🀠🀠🀠🀡"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(32);
	}

	@("A pair wait is worth two extra minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.eight);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀙🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀡"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(32);
	}

	@("A pon wait is not worth two extra minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.eight);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀙🀙🀙🀜🀜🀝🀝🀞🀞🀟🀟🀠🀠"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(40);
	}

	@("Nagashi mangan is 30 minipoints")
	unittest
	{
		import fluent.asserts;

		auto player = new Player("🀙🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀡"d);
		auto result = MahjongResult(true, [nagashiMangan()]);
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(30);
	}

	@("Set values are counted in the minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.character, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀇🀇🀉🀊🀋🀐🀐🀐🀒🀒🀙🀙🀙"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(50);
	}

	@("A self draw is 2 extra minipoints")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;

		auto wall = new MockWall(new Tile(Types.character, Numbers.one));
		auto player = new Player("🀇🀇🀉🀊🀋🀐🀐🀐🀒🀒🀙🀙🀙"d);
		player.drawTile(wall);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.calculateMiniPoints(PlayerWinds.east).should.equal(46);
	}

	bool isTsumo() @property pure const
	{
		return player.lastTile.isSelfDraw;
	}

	@("A self draw is tsumo")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.wall;

		auto wall = new MockWall(new Tile(Types.ball, Numbers.one));
		auto player = new Player("🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀠🀡"d);
		player.drawTile(wall);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.isTsumo.should.equal(true);
	}

	@("A win on a ronned tile is not a tsumo")
	unittest
	{
		import fluent.asserts;
		import mahjong.domain.opts;

		auto metagame = new Metagame([new Player], new DefaultGameOpts);
		auto tile = new Tile(Types.ball, Numbers.one);
		tile.isNotOwn;
		tile.isDiscarded;
		auto player = new Player("🀚🀛🀜🀜🀝🀝🀞🀞🀟🀠🀠🀠🀡"d);
		player.ron(tile, metagame);
		auto result = player.scanHandForMahjong;
		auto data = MahjongData(player, result);
		data.isTsumo.should.equal(false);
	}
}
