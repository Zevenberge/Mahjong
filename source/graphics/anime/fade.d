module mahjong.graphics.anime.fade;

import std.algorithm;
import std.conv;
import dsfml.graphics;
import mahjong.graphics.anime.animation;
/+
alias FadeRect = FadeAnimation!RectangleShape;
alias FadeSprite = FadeAnimation!Sprite;

class FadeAnimation(T) : Animation
{
	this(T fadable, int fadeSpeed)
	{
		_speed = fadeSpeed;
		_fader = fadable;
	}
	
	protected override void nextFrame()
	{
		static if(is(T == Sprite))
		{
			_fader.color.a = max(0, _fader.color.a - _speed).to!ubyte;
			done = _fader.color.a == 0;
		}
		else static if(is(T == Shape))
		{
			_fader.fillColor.a = max(0, _fader.fillColor.a - _speed).to!ubyte;
			_fader.outlineColor.a = max(0, _fader.outlineColor.a - _speed).to!ubyte;
			done = _fader.color.a == 0 && _fader.outlineColor.a == 0;
		}
	}

	private:
		int _speed;
		T _fader;
}
+/