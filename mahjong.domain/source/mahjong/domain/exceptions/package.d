module mahjong.domain.exceptions;

public import mahjong.domain.exceptions.illegalclaim;
public import mahjong.domain.exceptions.setnotfound;
public import mahjong.domain.exceptions.tilenotfound;

abstract class MahjongException : Exception
{
	this(string msg)
	{
		super(msg);
	}
}