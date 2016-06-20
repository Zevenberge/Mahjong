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
	int amountOfDiscardLines();
	int amountOfDiscardsPerLine();
}

StyleOpts styleOpts;

interface StyleOpts
{
	Vector2i screenSize();
	string screenHeader();
	int menuFontSize();
	Color menuFontColor();
	int menuTop();
	int menuSpacing();
}