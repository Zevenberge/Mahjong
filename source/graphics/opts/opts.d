module mahjong.graphics.opts.opts;

import dsfml.graphics;
import mahjong.domain.wall;
import mahjong.graphics.conv;
import mahjong.graphics.enums.geometry;

Opts drawingOpts;

interface Opts
{
	float rotationPerPlayer();
	float tileWidth();
	final Vector2f tileSize()
	{
		return Vector2f(tileWidth, tileWidth * TileSize.y / TileSize.x);
	}
	float iconSpacing();
	uint iconSize();
	int initialScore();
	int criticalScore();
	int amountOfDiscardLines();
	int amountOfDiscardsPerLine();
	void initialiseWall(Wall wall);
}

StyleOpts styleOpts;

interface StyleOpts
{
	Vector2i screenSize();
	Vector2i gameScreenSize();
	final Vector2f center()
	{
		return gameScreenSize.toVector2f/2;
	}
	string screenHeader();
	int gameInfoFontSize();
	Color gameInfoFontColor();
	int memoFontSize();
	Color memoFontColor();
	int menuFontSize();
	Color menuFontColor();
	int menuTop();
	int menuSpacing();
}