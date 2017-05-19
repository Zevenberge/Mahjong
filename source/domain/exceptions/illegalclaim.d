module mahjong.domain.exceptions.illegalclaim;

import std.string;
import mahjong.domain.exceptions;
import mahjong.domain.tile;

class IllegalClaimException : MahjongException
{
	this(const Tile tile, string msg)
	{
		super("Tried to claim %s but failed with reason %s".format(tile.face, msg));
	}
}
