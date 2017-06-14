module mahjong.graphics.anime.fade;

import std.algorithm;
import std.conv;
import dsfml.graphics;
import mahjong.graphics.anime.animation;

class AppearTextAnimation : Animation
{
	this(Text text, int amountOfFrames)
	{
		_text = text;
		_amountOfFrames = amountOfFrames;
	}

	private Text _text;
	private int _amountOfFrames;

	protected override void nextFrame()
	{
		auto color = _text.getColor;
		auto increment = (255 - color.a)/_amountOfFrames;
		_text.setColor(
			Color(color.r, color.g, color.b, (color.a + increment).to!ubyte)
			);
		--_amountOfFrames;
	}

	override protected bool done() @property
	{
		return _amountOfFrames == 0;
	}
}

class FadeSpriteAnimation : Animation
{
	this(Sprite sprite, int amountOfFrames)
	{
		_sprite = sprite;
		_amountOfFrames = amountOfFrames;
	}

	private Sprite _sprite;
	private int _amountOfFrames;
	
	protected override void nextFrame()
	{
		auto color = _sprite.color;
		auto increment = color.a/_amountOfFrames;
		_sprite.color = Color(color.r, color.g, color.b, (color.a - increment).to!ubyte);
		--_amountOfFrames;
	}

	protected override bool done() @property
	{
		return _amountOfFrames == 0;
	}
}
