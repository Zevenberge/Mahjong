module mahjong.graphics.text;

import std.conv;
import dsfml.graphics;
import mahjong.graphics.cache.font;
import mahjong.graphics.enums.font;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;

class TextFactory
{
	static Text resultText()
	{
		auto text = new Text;
		text.setFont(fontInfo);
		text.setCharacterSize(20);
		text.setColor(Color(255,255,255,0));
		return text;
	}
	static Text transferText()
	{
		auto text = new Text;
		text.setFont(fontInfo);
		text.setCharacterSize(40);
		text.setColor(Color(255,255,255,0));
		return text;
	}
}

void changeScoreHighlighting(Text text, Color defaultColor = pointsColor)
{
	auto score = text.getString.to!int;
	if(score < drawingOpts.criticalScore)
	{
		text.setColor(pointsCriticalColor);
	}
	else
	{
		text.setColor(defaultColor);
	}
}

void setTitle(Text title, string text)
{
	/*
	 Have a function that takes care of a uniform style for all title fields.
	 */
	with(title)
	{
		setFont(titleFont);
		setString(text);
		setCharacterSize(48);
		setColor(Color.Black);
		position = Vector2f(200,20);
	}
	auto size = styleOpts.gameScreenSize;
	title.center!(CenterDirection.Horizontal)(FloatRect(0, 0, size.x, size.y));
}