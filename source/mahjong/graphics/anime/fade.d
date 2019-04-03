module mahjong.graphics.anime.fade;

import std.conv;
import dsfml.graphics;
import mahjong.graphics.anime.animation;

alias AppearTextAnimation = AppearAnimation!Text;
alias AppearSpriteAnimation = AppearAnimation!Sprite;
class AppearAnimation(T) : Animation
{
	this(T item, int amountOfFrames)
	{
		_item = item;
		_amountOfFrames = amountOfFrames;
	}
	mixin ColorProperty!T;

	private T _item;
	private int _amountOfFrames;

	protected override void nextFrame()
	{
		auto color = getItemColor;
		auto increment = (255 - color.a)/_amountOfFrames;
		setItemColor(
			Color(color.r, color.g, color.b, (color.a + increment).to!ubyte)
			);
		--_amountOfFrames;
	}

	protected override void finishNow() 
	{
		_amountOfFrames = 1;
		nextFrame;
	}


	protected override bool done() @property
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

unittest
{
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.setColor(Color(255,255,255,0));
	auto animation = new AppearTextAnimation(text, 300);
	animation.forceFinish;
	assert(text.getColor.a == 255, "A short-circuit of the animation should result in a fully opaque text");
}

unittest
{
	auto sprite = new Sprite;
	sprite.color = Color(255,255,255,0);
	auto animation = new AppearSpriteAnimation(sprite, 300);
	animation.forceFinish;
	assert(sprite.color.a == 255, "The full functionality should also be available for a sprite");
}
alias FadeSpriteAnimation = FadeAnimation!Sprite;
alias FadeTextAnimation = FadeAnimation!Text;
class FadeAnimation(T) : Animation
{
	this(T item, int amountOfFrames)
	{
		_item = item;
		_amountOfFrames = amountOfFrames;
	}

	mixin ColorProperty!T;
	private T _item;
	private int _amountOfFrames;
	
	protected override void nextFrame()
	{
		auto color = getItemColor;
		auto increment = color.a/_amountOfFrames;
		setItemColor = Color(color.r, color.g, color.b, (color.a - increment).to!ubyte);
		--_amountOfFrames;
	}

	protected override void finishNow() 
	{
		_amountOfFrames = 1;
		nextFrame;
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

unittest
{
	auto sprite = new Sprite;
	sprite.color = Color(255, 255, 255, 255);
	auto animation = new FadeSpriteAnimation(sprite, 300);
	animation.forceFinish;
	assert(sprite.color.a == 0, "The sprite should be gone after being forced to finish");
}

unittest
{
	auto text = new Text;
	text.setColor = Color(255, 255, 255, 255);
	auto animation = new FadeTextAnimation(text, 300);
	animation.forceFinish;
	assert(text.getColor.a == 0, "The text should be gone after being forced to finish");
}

private mixin template ColorProperty(T)
{
	static if(is(T == Sprite))
	{
		private auto getItemColor()
		{
			return _item.color;
		}
		private void setItemColor(Color color)
		{
			_item.color = color;
		}
	}
	static if(is(T == Text))
	{
		private auto getItemColor()
		{
			return _item.getColor;
		}
		private void setItemColor(Color color)
		{
			_item.setColor = color;
		}
	}
}