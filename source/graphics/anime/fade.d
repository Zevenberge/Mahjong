module mahjong.graphics.anime.fade;

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

unittest
{
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.setColor(Color(255,255,255,1));
	auto animation = new AppearTextAnimation(text, 2);
	animation.animate;
	assert(text.getColor.a == 128, "The text should have appeared half");
	animation.animate;
	assert(text.getColor.a == 255, "The text should have fully appeared");
	assert(animation.done, "The animation should be done");
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

unittest
{
	auto sprite = new Sprite;
	sprite.color = Color(255, 255, 255, 254);
	auto animation = new FadeSpriteAnimation(sprite, 2);
	animation.animate;
	assert(sprite.color.a == 127, "The sprite should be half-gone");
	animation.animate;
	assert(sprite.color.a == 0, "The sprite should be gone");
	assert(animation.done, "The fade should be over");
}