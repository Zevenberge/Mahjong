module mahjong.domain.openhand;

import std.algorithm.iteration;
import std.array;

import mahjong.domain;
import mahjong.domain.enums.game;
import mahjong.domain.exceptions;
import mahjong.engine.mahjong;

class OpenHand
{
	private Tile[][] _sets;
	const(Tile[][]) sets() @property
	{
		return _sets;
	}

	private ubyte _amountOfPons;
	ubyte amountOfPons() @property
	{
		return _amountOfPons;
	}

	private ubyte _amountOfKans;
	ubyte amountOfKans() @property
	{
		return _amountOfKans;
	}

	void addPon(Tile[] tiles)
	in
	{
		assert(tiles.length == 3, "A pon should consist of three tiles.");
	}
	body
	{
		_sets ~= tiles;
		++_amountOfPons;
	}

	void addKan(Tile[] tiles)
	in
	{
		assert(tiles.length == 4, "A kan should consist of four tiles.");
	}
	body
	{
		_sets ~= tiles;
		++_amountOfPons;
		++_amountOfKans;
	}

	void promotePonToKan(Tile kanTile)
	{
		foreach(set; _sets)
		{
			if(set.length != 3) continue;
			if(!kanTile.hasEqualValue(set[0])) continue;
			set ~= kanTile;
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