module mahjong.engine.chi;

import mahjong.domain.tile;
import mahjong.share.range;

struct ChiCandidate
{
	const Tile first;
	const Tile second;
}

ChiCandidate[] determineChiCandidates(const(Tile)[] hand, const Tile discard) pure
{
	if(discard.isHonour) return null;
	enum distance = [-2, -1, 1, 2];
	ChiCandidate[] candidates;
	for(int i = 0; i < 3; ++i)
	{
		auto firstTile = hand.first!(t => t.type == discard.type && t.value == discard.value + distance[i]);
		auto secondTile = hand.first!(t => t.type == discard.type && t.value == discard.value + distance[i+1]);
		if(firstTile !is null && secondTile !is null) candidates ~= ChiCandidate(firstTile, secondTile);
	}
	return candidates;
}