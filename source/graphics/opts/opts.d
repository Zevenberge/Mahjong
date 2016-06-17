module mahjong.graphics.opts.opts;

import dsfml.graphics;

Opts drawingOpts;

interface Opts
{
	float rotationPerPlayer();
	float tileWidth();
	float iconSpacing();
	uint iconSize();
	int initialScore();
	int criticalScore();
	Vector2i screenSize();
	string screenHeader();
	
	int menuFontSize();
	Color menuFontColor();
}