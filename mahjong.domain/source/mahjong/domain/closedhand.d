module mahjong.domain.closedhand;

import std.algorithm;
import std.array;
import mahjong.domain;
import mahjong.domain.chi;
import mahjong.domain.exceptions;
import mahjong.domain.sort;
import mahjong.util.range;

class ClosedHand
{
	Tile[] tiles;

	size_t length() @property pure const
	{
		return tiles.length;
	}

	Tile removeTile(const Tile tile) pure
	{
		return tiles.remove!((a,b) => a is b)(tile);
	}

	void closeHand() pure
	{
		tiles.each!(t => t.close);
	}

	void showHand() pure
	{
		tiles.each!(t => t.open);
	}

	void drawTile(Wall wall) pure
	{
		addTile(wall.drawTile);
	}

	void drawKanTile(Wall wall) pure
	{
		addTile(wall.drawKanTile);
	}

	private void addTile(Tile tile) pure
	{
		tiles ~= tile;
		tiles.sortHand;
		_lastTile = tile;
	}

	private Tile _lastTile;
	Tile lastTile() @property pure
	{
		return _lastTile;
	}

	bool isChiable(const Tile discard) pure const
	{
		return !determineChiCandidates(tiles, discard).empty;
	}

	Tile[] removeChiTiles(const ChiCandidate otherChiTiles) pure
	out(tiles)
	{
		assert(tiles.length == 2, "Two tiles should have been removed");
		assert(tiles[0] !is null && tiles[1] !is null, "The tiles should have a value");
	}
	do
	{
		return [removeTile(otherChiTiles.first), 
			removeTile(otherChiTiles.second)];
	}

	bool isPonnable(const Tile discard) pure const
	{
		return countTilesWithEqualValue(discard) >= 2;
	}

	Tile[] removePonTiles(const Tile discard) pure
	in
	{
		assert(isPonnable(discard));
	}
	do
	{
		return removeTilesWithIdenticalValue!2(discard);
	}

	bool isKannable(const Tile discard) pure const
	{
		return countTilesWithEqualValue(discard) >= 3;
	}

	Tile[] removeKanTiles(const Tile discard) pure
	in
	{
		assert(isKannable(discard));
	}
	do
	{
		return removeTilesWithIdenticalValue!3(discard);
	}

	bool canDeclareClosedKan(const Tile tile) pure const
	{
		return tiles.count!(t => tile.hasEqualValue(t)) >= 4;
	}

	Tile[] declareClosedKan(const Tile tile)
	{
		if(!canDeclareClosedKan(tile)) throw new IllegalClaimException(tile, "Cannot declare a closed kan");
		return removeTilesWithIdenticalValue!4(tile);
	}

	private Tile[] removeTilesWithIdenticalValue(int amount)(const Tile other) pure
	{
		import std.range : take;

		auto removedTiles = getTilesWithEqualValue(other).take(amount).array;
		tiles = tiles.without!((a,b) => a is b)(removedTiles);
		return removedTiles;
	}

	private auto getTilesWithEqualValue(const Tile other) pure
	{
		return tiles.filter!(tile => tile.hasEqualValue(other));
	}

	private size_t countTilesWithEqualValue(const Tile other) pure const
	{
		return tiles.count!(tile => tile.hasEqualValue(other));
	}
}

unittest
{
	import mahjong.domain.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	assert(!closedHand.canDeclareClosedKan(closedHand.tiles.front), 
		"As there are only three copies of the tile in the hand, no closed kan can be claimed");
	assert(closedHand.canDeclareClosedKan(closedHand.tiles.back), 
		"As there are four copies of the tile, a closed kan can be declared.");
}

unittest
{
	import mahjong.domain.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	auto initialLength = closedHand.tiles.length;
	auto tile = closedHand.tiles.back;
	auto kanTiles = closedHand.declareClosedKan(tile);
	assert(kanTiles.length == 4, "Four tiles should be returned when a closed kan is declared");
	assert(kanTiles.all!(kt => tile.hasEqualValue(kt)), "All returned tiles should have the same value as the requested tile");
	assert(closedHand.tiles.length == initialLength - 4, "Four tiles should have been subtracted from the hand");
	assert(!closedHand.tiles.any!(t => tile.hasEqualValue(t)), "All tiles with the requested value should have been removed");
}
unittest
{
	import std.exception;
	import mahjong.domain.creation;
	auto closedHand = new ClosedHand;
	closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
	assertThrown!IllegalClaimException(closedHand.declareClosedKan(closedHand.tiles.front), 
		"Trying to declare a closed kan when it is not allowed should be rewarded with an exception.");
}

bool hasNineOrMoreUniqueHonoursOrTerminals(const ClosedHand hand)
{
    auto honoursOrTerminals = hand.tiles.filter!(t => t.isHonourOrTerminal);
    auto uniqueHonoursOrTerminals = honoursOrTerminals.uniq!((a, b) => a.hasEqualValue(b));
    return uniqueHonoursOrTerminals.count >= 9;
}

@("A hand with less than 9 honours or terminals should not be eligible for redraw")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto hand = new ClosedHand;
    hand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
    hand.hasNineOrMoreUniqueHonoursOrTerminals.should.equal(false);
}

@("A hand with 9 or more honours of terminals is eligible for redraw")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto hand = new ClosedHand;
    hand.tiles = "🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d.convertToTiles;
    hand.hasNineOrMoreUniqueHonoursOrTerminals.should.equal(true);
}

@("Doubles do not count for redraw")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto hand = new ClosedHand;
    hand.tiles = "🀀🀁🀂🀃🀄🀅🀆🀆🀏🀝🀟🀟🀠🀠"d.convertToTiles;
    hand.hasNineOrMoreUniqueHonoursOrTerminals.should.equal(false);
}