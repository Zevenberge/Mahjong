module mahjong.domain.exceptions;

public import mahjong.domain.exceptions.illegalclaim;

abstract class MahjongException : Exception
{
	this(string msg)
	{
		super(msg);
	}
}