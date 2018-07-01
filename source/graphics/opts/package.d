module mahjong.graphics.opts;

public import mahjong.graphics.opts.defaultopts;
public import mahjong.graphics.opts.bambooopts;

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
	void initialiseWall(const Wall wall);
	void placeCounter(Sprite counter);
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
	int gameInfoMargin();
	int gameInfoFontSize();
	Color gameInfoFontColor();
	int memoFontSize();
	Color memoFontColor();
	int menuFontSize();
	Color menuFontColor();
	Color menuHazeColor();
	Color ingameMenuHazeColor();
	Color mahjongResultsHazeColor();
	int menuTop();
	int menuSpacing();
	int ingameMenuMargin();
	Vector2f popupSplashSize();
	int popupFontSize();

}


