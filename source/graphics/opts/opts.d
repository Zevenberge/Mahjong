module mahjong.graphics.opts.opts;

Opts drawingOpts;

interface Opts
{
	float rotationPerPlayer();
	float tileWidth();
	float iconSpacing();
	uint iconSize();
	int initialScore();
	int criticalScore();
}