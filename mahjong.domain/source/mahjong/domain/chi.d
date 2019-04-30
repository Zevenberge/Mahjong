module mahjong.domain.chi;

import std.algorithm;
import std.array;
import mahjong.domain.tile;
import mahjong.util.range;

struct ChiCandidate
{
	const Tile first;
	const Tile second;
}

ChiCandidate[] determineChiCandidates(const(Tile)[] hand, const Tile discard) pure
{
	if(discard.isHonour) return null;
	static immutable distance = [-2, -1, 1, 2];
	ChiCandidate[] candidates;
	for(int i = 0; i < 3; ++i)
	{
		auto firstTile = hand.first!(t => t.type == discard.type && t.value == discard.value + distance[i]);
		auto secondTile = hand.first!(t => t.type == discard.type && t.value == discard.value + distance[i+1]);
		if(firstTile !is null && secondTile !is null) candidates ~= ChiCandidate(firstTile, secondTile);
	}
	return candidates;
}

bool isChi(ChiCandidate candidate, const Tile discard) pure
{
	auto isSameType = discard.type == candidate.first.type
		&& discard.type == candidate.second.type;
	auto isHonour = discard.isHonour;
	auto values = [candidate.first.value, candidate.second.value, discard.value];
	auto minValue = min(values[0], values[1], values[2]);
	auto hasConstructiveValues = values.any!(v => v == minValue +1) 
		&& values.any!(v => v == minValue+2);
	return isSameType && !isHonour && hasConstructiveValues;
}