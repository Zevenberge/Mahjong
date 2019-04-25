module mahjong.domain.openhand;

import std.algorithm;
import std.array;
import std.uuid;

import mahjong.domain.exceptions;
import mahjong.domain.set;
import mahjong.domain.tile;
import mahjong.engine.opts;
import mahjong.share.range;

class OpenHand
{
	this()
	{
		id = randomUUID;
	}

	const UUID id;

	const(Tile)[] tiles() @property const
	{
		return _sets.flatMap!(set => set.tiles);
	}

	bool isClosedHand() @property pure const
	{
		return _sets.all!(s => !s.isOpen);
	}

	private Set[] _sets;
	const(Set[]) sets() @property pure const
	{
		return _sets;
	}

	size_t amountOfPons() @property pure const
	{
		return _sets.count!(s => cast(PonSet)s !is null);
	}

	private ubyte _amountOfKans;
	size_t amountOfKans() @property pure const
	{
		return _amountOfKans;
	}

	size_t amountOfChis() @property pure const
	{
		return _sets.count!(s => cast(ChiSet)s !is null);
	}

	void addPon(Tile[] tiles) pure
	in
	{
		assert(tiles.length == 3, "A pon should consist of three tiles.");
	}
	body
	{
		_sets ~= new PonSet(tiles);
	}

	void addKan(Tile[] tiles) pure
	in
	{
		assert(tiles.length == 4, "A kan should consist of four tiles.");
	}
	body
	{
		_sets ~= new PonSet(tiles);
		++_amountOfKans;
	}

	void addChi(Tile[] tiles) pure
	in 
	{
		assert(tiles.length == 3, "A chi should have the length of three tiles");
	}
	body
	{
		_sets ~= new ChiSet(tiles);
	}

	bool canPromoteToKan(const Tile tile) pure const
	{
		return _sets.any!(s => s.canPromoteSetToKan(tile));
	}

	void promoteToKan(Tile kanTile)
	{
		foreach(i, set; _sets)
		{
			if(!set.canPromoteSetToKan(kanTile)) continue;
			_sets = _sets.remove(i);
			_sets = _sets.insertAt(new PonSet(set.tiles ~ kanTile), i);
			++_amountOfKans;
			return;
		}
		throw new SetNotFoundException(kanTile);
	}

	const(Set) findCorrespondingPon(const(Tile) tile) const
	{
		foreach(set; _sets)
		{
			if(set.canPromoteSetToKan(tile)) return set;
		}
		throw new SetNotFoundException(tile);

	}
}

unittest
{
	import mahjong.engine.creation;
	auto openHand = new OpenHand;
	auto pon = "🀀🀀🀀"d.convertToTiles;
	openHand.addPon(pon);
	assert(openHand.amountOfPons == 1, "Hand should have one pon");
	assert(openHand.amountOfKans == 0, "Hand should have no kans");
}

unittest
{
	import mahjong.engine.creation;
	auto openHand = new OpenHand;
	auto kan = "🀀🀀🀀🀀"d.convertToTiles;
	openHand.addKan(kan);
	assert(openHand.amountOfPons == 1, "Hand should have one pon");
	assert(openHand.amountOfKans == 1, "Hand should have one kan");
}

unittest
{
	import mahjong.engine.creation;
	auto openHand = new OpenHand;
	auto pon = "🀀🀀🀀"d.convertToTiles;
	auto kanTile = "🀀"d.convertToTiles[0];
	openHand.addPon(pon);
	openHand.promoteToKan(kanTile);
	assert(openHand.amountOfPons == 1, "Hand should have one pon");
	assert(openHand.amountOfKans == 1, "Hand should have one kan");
}

private bool canPromoteSetToKan(const Set set, const Tile kanTile) pure
{
	return set.tiles.length == 3 &&
			kanTile.hasEqualValue(set.tiles[0]) &&
			set.isPon;
}

unittest
{
	import mahjong.engine.creation;
	auto pon = new PonSet("🀀🀀🀀"d.convertToTiles);
	auto kanTile = "🀀"d.convertToTiles[0];
	assert(pon.canPromoteSetToKan(kanTile), "Pon should be promotable to kan.");
}
unittest
{
	import mahjong.engine.creation;
	auto pon = new PonSet("🀀🀀🀀🀀"d.convertToTiles);
	auto kanTile = "🀀"d.convertToTiles[0];
	assert(!pon.canPromoteSetToKan(kanTile), "Kan should not be promotable to kan.");
}
unittest
{
	import mahjong.engine.creation;
	auto pon = new PonSet("🀟🀟🀟"d.convertToTiles);
	auto kanTile = "🀀"d.convertToTiles[0];
	assert(!pon.canPromoteSetToKan(kanTile), "A different pon should not be promotable to kan.");
}
unittest
{
	import mahjong.engine.creation;
	auto chi = new ChiSet("🀟🀠🀡"d.convertToTiles);
	auto kanTile = "🀟"d.convertToTiles[0];
	assert(!chi.canPromoteSetToKan(kanTile), "A different chi should not be promotable to kan.");
}

bool hasAllKans(const OpenHand hand, int maxAmountOfKans) pure
{
    return hand.amountOfKans == maxAmountOfKans;
}

unittest
{
    import fluent.asserts;
    auto hand = new OpenHand;
    hand.hasAllKans(4).should.equal(false);
    hand._amountOfKans = 3;
    hand.hasAllKans(4).should.equal(false);
    hand._amountOfKans = 4;
    hand.hasAllKans(4).should.equal(true);
}