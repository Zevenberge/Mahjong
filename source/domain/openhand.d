module mahjong.domain.openhand;

import std.algorithm;
import std.array;
import std.uuid;

import mahjong.domain;
import mahjong.domain.enums.game;
import mahjong.domain.exceptions;
import mahjong.engine.mahjong;
import mahjong.share.range;

class OpenHand
{
	this()
	{
		id = randomUUID;
	}

	const UUID id;

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

	void addPon(Tile[] tiles)
	in
	{
		assert(tiles.length == 3, "A pon should consist of three tiles.");
	}
	body
	{
		_sets ~= new PonSet(tiles);
	}

	void addKan(Tile[] tiles)
	in
	{
		assert(tiles.length == 4, "A kan should consist of four tiles.");
	}
	body
	{
		_sets ~= new PonSet(tiles);
		++_amountOfKans;
	}

	void addChi(Tile[] tiles)
	in 
	{
		assert(tiles.length == 3, "A chi should have the length of three tiles");
	}
	body
	{
		_sets ~= new ChiSet(tiles);
	}

	void promotePonToKan(Tile kanTile)
	{
		foreach(i, set; _sets)
		{
			if(set.tiles.length != 3) continue;
			if(!kanTile.hasEqualValue(set.tiles[0])) continue;
			_sets.remove(i);
			_sets.insertAt(new PonSet(set.tiles ~ kanTile), i);
			++_amountOfKans;
			return;
		}
		throw new SetNotFoundException(kanTile);
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
	openHand.promotePonToKan(kanTile);
	assert(openHand.amountOfPons == 1, "Hand should have one pon");
	assert(openHand.amountOfKans == 1, "Hand should have one kan");
}