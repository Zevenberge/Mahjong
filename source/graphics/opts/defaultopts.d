module mahjong.graphics.opts.defaultopts;

import dsfml.graphics;
import mahjong.domain.wall;
import mahjong.graphics.drawing.wall;
import mahjong.graphics.opts.opts;

class DefaultDrawingOpts : Opts
{
	float rotationPerPlayer()
	{
		return -90;
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
	
	int amountOfDiscardLines()
	{
		return 3;
	}
	int amountOfDiscardsPerLine()
	{
		return 6;
	}
	void initialiseWall(Wall wall)
	in{}
	body
	{
		initialiseTiles(wall);
	}
}

class DefaultStyleOpts : StyleOpts
{
	Vector2i screenSize()
	{
		return Vector2i(900,1000);
	}
	Vector2i gameScreenSize()
	{
		return Vector2i(900,900);
	}
	string screenHeader()
	{
		return "Mahjong";
	}
	int gameInfoMargin()
	{
		return 10;
	}
	int gameInfoFontSize()
	{
		return 48;
	}
	Color gameInfoFontColor()
	{
		return Color(0, 0, 0, 200);
	}
	int memoFontSize()
	{
		return 20;
	}
	Color memoFontColor()
	{
		return Color.Black;
	}
	int menuFontSize()
	{
		return 32;
	}
	Color menuFontColor()
	{
		return Color.Black;
	}
	int menuTop()
	{
		return 250;
	}
	int menuSpacing()
	{
		return 20;
	}
	int popupFontSize()
	{
		return 48;
	}
}









