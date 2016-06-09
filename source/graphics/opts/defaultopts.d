module mahjong.graphics.opts.defaultopts;

import mahjong.graphics.opts.opts;

class DefaultOpts : Opts
{
	float rotationPerPlayer()
	{
		return 90;
	}
	float tileWidth()
	{
		return 30;
	}
	float iconSpacing()
	{
		return 25;
	}
	uint iconSize()
	{
		return 150;
	}
	int initialScore()
	{
		return 30_000;
	}
	int criticalScore()
	{
		return 10_000;
	}
}