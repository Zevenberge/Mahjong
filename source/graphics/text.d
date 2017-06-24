module mahjong.graphics.text;

import std.conv;
import dsfml.graphics;
import mahjong.graphics.cache.font;
import mahjong.graphics.enums.font;
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