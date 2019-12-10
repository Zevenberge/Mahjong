module mahjong.domain.chi;

import std.algorithm;
import std.array;
import std.typecons;
import mahjong.domain.tile;
import mahjong.util.range;

struct ChiCandidate
{
	const Tile first;
	const Tile second;
}

bool isChiable(const(Tile)[] hand, const Tile discard) pure @nogc nothrow
{
	return determineChis!(No.returnSets)(hand, discard);
}

ChiCandidate[] determineChiCandidates(const(Tile)[] hand, const Tile discard) pure nothrow
{
	return determineChis!(Yes.returnSets)(hand, discard);
}

private auto determineChis(Flag!"returnSets" returnSets)(const(Tile)[] hand, const Tile discard) pure nothrow
{
	if(discard.isHonour)
	{
		static if(returnSets == Yes.returnSets)
			return null;
		else
			return false;
	}
	static immutable distance = [-2, -1, 1, 2];
	static if(returnSets == Yes.returnSets)
		ChiCandidate[] candidates;
	for(int i = 0; i < 3; ++i)
	{
		auto firstTile = hand.first!(t => t.type == discard.type && t.value == discard.value + distance[i]);
		auto secondTile = hand.first!(t => t.type == discard.type && t.value == discard.value + distance[i+1]);
		if(firstTile !is null && secondTile !is null)
		{
			static if(returnSets == Yes.returnSets)
				candidates ~= ChiCandidate(firstTile, secondTile);
			else
				return true;
		}
	}
	static if(returnSets == Yes.returnSets)
		return candidates;
	else 
		return false;
}

bool isChi(ChiCandidate candidate, const Tile discard) pure @nogc nothrow
{
	auto isSameType = discard.type == candidate.first.type
		&& discard.type == candidate.second.type;
	auto isHonour = discard.isHonour;
	const(int)[3] values = [candidate.first.value, candidate.second.value, discard.value];
	auto minValue = min(values[0], values[1], values[2]);
	auto hasConstructiveValues = values[].any!(v => v == minValue +1) 
		&& values[].any!(v => v == minValue+2);
	return isSameType && !isHonour && hasConstructiveValues;
}