module mahjong.graphics.opts.defaultopts;

import dsfml.graphics;
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
}

class DefaultStyleOpts : StyleOpts
{
	Vector2i screenSize()
	{
		return Vector2i(900,900);
	}
	string screenHeader()
	{
		return "Mahjong";
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
}









