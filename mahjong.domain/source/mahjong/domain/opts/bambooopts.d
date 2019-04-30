module mahjong.domain.opts.bambooopts;

import mahjong.domain;
import mahjong.domain.enums;
import mahjong.domain.opts;

class DefaultBambooOpts : DefaultGameOpts
{
	override int amountOfPlayers() pure const
	{
		return 2;
	}
	override int deadWallLength() pure const
	{
		return 0;
	}
	override GameMode gameMode() pure const
	{
		return GameMode.Bamboo;
	}
	override PlayerWinds finalLeadingWind() pure const
	{
		return PlayerWinds.north;
	}
    override Wall createWall() pure const 
    {
        return new BambooWall(this);
    }
}