module mahjong.engine.mahjong;

import std.experimental.logger;
import std.algorithm;
import std.array;
import std.conv; 

import mahjong.domain.closedhand;
import mahjong.domain.enums;
import mahjong.domain.openhand;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.result;
import mahjong.domain.set;
import mahjong.domain.tile;
import mahjong.engine.sort;
import mahjong.share.range;
import mahjong.share.numbers;

MahjongResult scanHandForMahjong(const Ingame player) pure
{
	return scanHandForMahjong(player.closedHand.tiles, player.openHand.sets);
}

MahjongResult scanHandForMahjong(const Ingame player, const Tile discard) pure
{
	return scanHandForMahjong(player.closedHand.tiles ~ discard, player.openHand.sets);
}

unittest
{
	import mahjong.engine.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto openHand = new OpenHand;
	openHand.addPon("🀃🀃🀃"d.convertToTiles);
	auto ingame = new Ingame(PlayerWinds.south);
	ingame.closedHand = closedHand;
	ingame.openHand = openHand;
	assert(scanHandForMahjong(ingame).isMahjong, "An open pon should count towards mahjong");
}

unittest
{
	import mahjong.engine.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto openHand = new OpenHand;
	openHand.addChi("🀓🀔🀕"d.convertToTiles);
	auto ingame = new Ingame(PlayerWinds.east);
	ingame.closedHand = closedHand;
	ingame.openHand = openHand;
	assert(scanHandForMahjong(ingame).isMahjong, "An open chi should count towards mahjong");
}

private MahjongResult scanHandForMahjong(const(Tile)[] hand, const(Set[]) openSets) pure 
in {assert(hand.length > 0);}
out {assert(hand.length > 0);}
body
{ /*
	   See if the current hand is a legit mahjong hand.
	   */
	auto sortedHand = sortHand(hand);
	// Run a dedicated scan for thirteen orphans
	if(hand.length == 14) 
	{
		if(isThirteenOrphans(sortedHand))
		{ 
			return MahjongResult(true, [new ThirteenOrphanSet(sortedHand)]);
		}
	}

	auto progress = scanRegularMahjong(new Progress(sortedHand, openSets));
	const(Set)[] sets;
	sets ~= progress.pons;
	sets ~= progress.chis;
	sets ~= progress.pairs;
	auto result = MahjongResult(progress.isMahjong, sets);

    if(hand.length == 14 && !progress.isMahjong) 
    { // If we don't have a mahjong using normal hands, we check whether we have seven pairs
        if(isSevenPairs(sortedHand))
        {
            return MahjongResult(true, [new SevenPairsSet(sortedHand)]);
        }
    }
    return result;
}

private bool isSevenPairs(const Tile[] hand) pure
{ 
	if(hand.length != 14) return false;
	for(int i=0; i<7; ++i)
	{
		if(hand.length > 2*i+2) 
		{ // Check if no two pairs are the same, only if the hand size allows it.
			if(hand[2*i].hasEqualValue(hand[2*i+2]))
			{ 
				return false;
			} // Return if we have three identical tiles.
		}
		if(!hand[2*i].hasEqualValue(hand[2*i+1]))
		{ // Check whether is is a pair.
			return false;
		}  // If it is no pair, it is no seven pairs hand.
	}
	return true;
}

private bool isThirteenOrphans(const Tile[] hand) pure
{

	if(hand.length != 14) return false;
	int pairs = 0;
	
	for(int i = 0; i < 13; ++i)
	{ 
		ComparativeTile honour;

		switch(i){
			case 0: .. case 3: // Winds
				honour = ComparativeTile(Types.wind, i);
				break;
			case 4: .. case 6: // Dragons
				honour = ComparativeTile(Types.dragon, i % (Winds.max + 1));
				break;
			case 7, 8:         // Characters
				honour = ComparativeTile(Types.character, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			case 9, 10:        // Bamboos
				honour = ComparativeTile(Types.bamboo, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			case 11, 12:       // Balls
				honour = ComparativeTile(Types.ball, i.isOdd ? Numbers.one : Numbers.nine);
				break;
			default:
				assert(false);
		}
		if(!honour.hasEqualValue(hand[i+pairs])) //If the tile is not the honour we are looking for
		{ 
			return false;  
		}
		if((i + pairs + 1) < hand.length) 
		{
			if(hand[i+pairs].hasEqualValue(hand[i+pairs+1])) // If we have a pair
			{
				++pairs;
				if(pairs > 1)
				{
					return false;
				}  // If we have more than one pair, it is not thirteen orphans.
			}
		}
	}
	/*
	 When the code arrives at this point, we have confirmed that the hand has each of the thirteen orphans in it. The final check is whether the hand also has the pair.
	 */

	return pairs == 1;
}

private class Progress
{
	this(const(Tile)[] hand, const(Set[]) initialSets) pure
	{
		this.hand = hand;
		foreach(set; initialSets)
		{
			auto pon = cast(const(PonSet))set;
			if(pon) pons ~= pon;
			auto chi = cast(const(ChiSet))set;
			if(chi) chis ~= chi;
		}
	}

	const(Tile)[] hand;
	const(PairSet)[] pairs;
	const(PonSet)[] pons;
	const(ChiSet)[] chis;

	void convertToPair(const HandSetSeperation handSetSeperation) pure
	{
		if(!handSetSeperation.isSeperated) return;
		hand = handSetSeperation.hand;
		pairs ~= new PairSet(handSetSeperation.set);
	}

	void convertToPon(const HandSetSeperation handSetSeperation) pure
	{
		if(!handSetSeperation.isSeperated) return;
		hand = handSetSeperation.hand;
		pons ~= new PonSet(handSetSeperation.set);
	}

	void convertToChi(const HandSetSeperation handSetSeperation) pure
	{
		if(!handSetSeperation.isSeperated) return;
		hand = handSetSeperation.hand;
		chis ~= new ChiSet(handSetSeperation.set);
	}

	void subtractPair() pure
	{
		auto pair = pairs[$-1];
		recoverTiles(pair.tiles);
		pairs = pairs[0 .. $-1];
	}

	void subtractPon() pure
	{
		auto pon = pons[$-1];
		recoverTiles(pon.tiles);
		pons = pons[0 .. $-1];
	}

	void subtractChi() pure
	{
		auto chi = chis[$-1];
		recoverTiles(chi.tiles);
		chis = chis[0 .. $-1];
	}

	private void recoverTiles(const(Tile)[] tiles) pure
	{
		hand = sortHand(hand ~ tiles);
	}

	private bool _isMahjong;
	bool isMahjong() @property pure const
	{
		return _isMahjong || (pairs.length == 1 &&
			pons.length + chis.length == 4);
	}
}

private struct HandSetSeperation
{
	const (Tile)[] hand;
	const (Tile)[] set;
	bool isSeperated() @property pure const
	{
		return set.length > 0;
	}
}

private Progress scanRegularMahjong(Progress progress) pure
{ 
	/*
	   It first checks if the first two tiles form a pair (max. 1). 
	   Then it checks if the first three tiles form a pon. If it fails, it returns a false.

	   pairs --- pons  --- chis                <- finds a pair
	   +- pons  --- chis                <- finds a pon
	   +- pons  -- chis       <- finds nothing and returns to the previous layer, in which it can still find a chi.

	*/
	if(progress.pairs.length < 1)
	{ // Check if there is a pair, but only if there is not yet a pair.
		progress = attemptToResolvePair(progress);
		if(progress.isMahjong) return progress;
	}
	progress = attemptToResolvePon(progress);
	if(progress.isMahjong) return progress;
	return attemptToResolveChi(progress);
}

private Progress attemptToResolvePair(Progress progress) pure
{
	if(progress.hand.length < 2) return progress;
	auto pairSeperation = seperateEqualSetOfGivenLength(progress.hand, 2);
	progress.convertToPair(pairSeperation);
	if(!pairSeperation.isSeperated) return progress;
	progress = scanRegularMahjong(progress);
	if(!progress.isMahjong) 
	{
		progress.subtractPair;
	}
	return progress;
}

private Progress attemptToResolvePon(Progress progress) pure
{
	if(progress.hand.length < 3) return progress;
	auto ponSeperation = seperateEqualSetOfGivenLength(progress.hand, 3);
	progress.convertToPon(ponSeperation);
	if(!ponSeperation.isSeperated) return progress;
	progress = scanRegularMahjong(progress);
	if(!progress.isMahjong) 
	{
		progress.subtractPon;
	}
	return progress;
}

private Progress attemptToResolveChi(Progress progress) pure
{
	if(progress.hand.length < 3) return progress;
	if(progress.hand[0].isHonour)
	{
		// Honours cannot be resolved in a chi.
		return progress;
	}
	auto chiSeperation = seperateChi(progress.hand);
	if(!chiSeperation.isSeperated) return progress;
	progress.convertToChi(chiSeperation);
	progress = scanRegularMahjong(progress);
	if(!progress.isMahjong)
	{
		progress.subtractChi;
	}
	return progress;
}

private HandSetSeperation seperateChi(const(Tile)[] hand) pure
{ 
	/*
	   This subroutine checks whether there is a chi hidden in the beginning of the hand. 
	   It should also take into account that there could be doubles, 
	   i.e. 1-2-2-2-3. Subtract the chi from the initial hand.
	*/

	const(Tile)[] chi;
	chi ~= hand[0];
	foreach(tile; hand.filter!(t => t.type == chi[0].type))
	{
		if(tile.value == chi[$-1].value + 1)
		{
			chi ~= tile;
			if(chi.length == 3) 
			{
				return HandSetSeperation(hand.without!((a,b) => a.id == b.id)(chi), chi);
			}
		}
	}
	return HandSetSeperation(hand);
}

private HandSetSeperation seperateEqualSetOfGivenLength(const(Tile)[] hand, const int distance) pure 
{ 
	/* distance = set.pair or set.pon
	   This subroutine checks if the first few tiles form a set and then subtracts them from the inititial hand.
	*/
	if(hand.length < distance) return HandSetSeperation(hand, null);
	auto tile = hand[0];
	auto equalTiles = hand.filter!(t => t.hasEqualValue(tile)).array;
	if(equalTiles.length < distance) return HandSetSeperation(hand, null);
	auto set = equalTiles[0 .. distance];
	return HandSetSeperation(
		hand.without!((a,b) => a.id == b.id)(set), 
		set);
}

@("Are the example hands mahjong hands?")
unittest // Check whether the example hands are seen as mahjong hands.
{
	import std.stdio;
	import std.path;
	import std.string;

	void testHands(string filename, const bool isHand)
	{
		writeln("Looking for ", filename.asAbsolutePath);
		auto output = readLines(filename);
		foreach(line; output)
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

version(unittest)
{
    import std.file;
	import std.range;
	import std.stdio;
    import std.string;
	import mahjong.engine.creation;
	/// Read the given file into dstring lines
	dstring[] readLines(string filename)
	{ 
		if(exists(filename))
		{ 
			dstring[] output;
			auto file = File(filename,"r");
			while(!file.eof())
			{
				string line = chomp(file.readln());
				dchar[] dline;
				foreach(face; stride(line,1))
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
    import mahjong.engine.creation;
    return allTiles.any!(tile => scanHandForMahjong(closedHand ~tile, openHand.sets).isMahjong);
}

@("Is the player tenpai")
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
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
    import mahjong.engine.creation;
    auto tenpaiHand = "🀀🀁🀂🀃🀄🀆🀆🀇🀏🀐🀘🀙🀡"d.convertToTiles;
    auto emptyOpenHand = new OpenHand;
    isPlayerTenpai(tenpaiHand, emptyOpenHand).should.equal(true);
}

auto constructMahjongData(Metagame metagame)
{
    bool isExhaustiveDraw = metagame.isExhaustiveDraw;
    return metagame.playersByTurnOrder
        .map!(p => p.calculateMahjongData(isExhaustiveDraw))
        .filter!(data => data.result.isMahjong).array;
}

unittest
{
    import std.range;
    import fluent.asserts;
    import mahjong.engine.opts;
    auto winningGame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto losingGame = new Ingame(PlayerWinds.west, "🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
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

private MahjongData calculateMahjongData(const Player player, bool isExhaustiveDraw)
{
    if(isExhaustiveDraw)
    {
        return MahjongData(player, MahjongResult(player.isNagashiMangan, [new NagashiManganSet]));
    }
    else
    {
        auto mahjongResult = scanHandForMahjong(player);
        return MahjongData(player, mahjongResult);
    }
}

@("If a player is mahjong, it should be concluded as such")
unittest
{
    import fluent.asserts;
    auto winningGame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto player = new Player;
    player.game = winningGame;
    auto result = player.calculateMahjongData(false);
    result.isMahjong.should.equal(true);
}

@("If a player is not mahjong, it should also be concluded as such")
unittest
{
    import fluent.asserts;
    auto losingGame = new Ingame(PlayerWinds.west, "🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
    auto player = new Player;
    player.game = losingGame;
    auto result = player.calculateMahjongData(false);
    result.isMahjong.should.equal(false);
}

@("If the game is an exhaustive draw, a nagashi mangan is counted as a mahjong")
unittest
{
    import fluent.asserts;
    auto losingGame = new Ingame(PlayerWinds.west, "🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
    auto player = new Player;
    player.game = losingGame;
    auto result = player.calculateMahjongData(true);
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
    size_t calculateMiniPoints(PlayerWinds leadingWind) pure const
    {
        alias isSevenPairHand = mahjong.domain.result.isSevenPairs;
        if(isSevenPairHand(result)) return 25;
        auto miniPointsFromSets = result.calculateMiniPoints(player.wind.to!PlayerWinds, leadingWind);
        auto miniPointsFromWinning = isTsumo ? 30 : 20;
        return miniPointsFromSets + miniPointsFromWinning;
    }

    bool isTsumo() @property pure const
    {
        return player.lastTile.isOwn;
    }
}

unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.tile;
    import mahjong.domain.wall;
    import mahjong.engine.creation;
    auto wall = new MockWall(new Tile(Types.ball, Numbers.six));
    auto player = new Player();
    player.game = new Ingame(PlayerWinds.east);
    player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀟"d.convertToTiles;
    player.drawTile(wall);
    auto mahjongResult = player.scanHandForMahjong;
    auto data = MahjongData(player, mahjongResult);
    assert(data.isTsumo, "Being mahjong after drawing a tile is a tsumo"); 
    assert(data.calculateMiniPoints(PlayerWinds.south) == 40, "Pon of honours + pair of dragons + tsumo = 40");
}

unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.tile;
    import mahjong.engine.creation;
    auto player = new Player();
    player.game = new Ingame(PlayerWinds.east);
    player.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗"d.convertToTiles;
    auto tile = new Tile(Types.bamboo, Numbers.eight);
    tile.origin = new Ingame(PlayerWinds.south);
    player.ron(tile);
    auto mahjongResult = player.scanHandForMahjong;
    auto data = MahjongData(player, mahjongResult);
    assert(!data.isTsumo, "Being mahjong after ron is not a tsumo"); 
    assert(data.calculateMiniPoints(PlayerWinds.south) == 25, "Seven pairs is always 25, regardless of what pairs");
}

unittest
{
    import mahjong.domain.ingame;
    import mahjong.domain.tile;
    import mahjong.domain.wall;
    import mahjong.engine.creation;
    auto wall = new MockWall(new Tile(Types.ball, Numbers.six));
    auto player = new Player();
    player.game = new Ingame(PlayerWinds.east);
    player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀟"d.convertToTiles;
    auto tile = new Tile(Types.wind, Winds.east);
    tile.origin = new Ingame(PlayerWinds.south);
    player.kan(tile, wall);
    auto mahjongResult = player.scanHandForMahjong;
    auto data = MahjongData(player, mahjongResult);
    assert(data.isTsumo, "Being mahjong after kan is a tsumo"); 
    assert(data.calculateMiniPoints(PlayerWinds.south) == 48, "Open kan of honours + pair of dragons + tsumo = 48");
}

