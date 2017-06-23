module mahjong.graphics.anime.count;

import std.algorithm.comparison;
import std.conv;
import std.math;
import dsfml.graphics;
import mahjong.graphics.anime.animation;
import mahjong.graphics.manipulation;

class CountAnimation : Animation
{
	this(Text text, int initialValue, int finalValue)
	{
		_text = text;
		_value = initialValue;
		_finalValue = finalValue;
	}

	private Text _text;
	private int _value;
	private const int _finalValue;
	private size_t _amountOfFramesEclapsed;

	override bool done() @property
	{
		return _value == _finalValue;
	}

	protected override void nextFrame() 
	{
		_amountOfFramesEclapsed++;
		auto increment = _amountOfFramesEclapsed.pow(1.3).to!int;
		if(isAddition)
		{
			_value += increment;
			_value = min(_finalValue, _value);
		}
		else
		{
			_value -= increment;
			_value = max(_finalValue, _value);
		}
		updateText;
	}

	private bool isAddition() @property pure const
	{
		return _finalValue > _value;
	}

	protected override void finishNow() 
	{
		_value = _finalValue;
		updateText;
	}

	private void updateText()
	{
		auto bounds = _text.getGlobalBounds;
		_text.setString = _value.to!string;
		_text.alignRight(bounds);
	}
}

unittest
{
	import fluent.asserts;
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.setFont = infoFont;
	text.setString = "0";
	auto animation = new CountAnimation(text, 0, 1);
	animation.animate;
	text.getString.to!int.should.equal(1).because("The number should have been upped.");
	assert(animation.done, "The animation reached its target and should be done.");
}

unittest
{
	import fluent.asserts;
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.setFont = infoFont;
	text.setString = "0";
	auto animation = new CountAnimation(text, 0, 1000);
	animation.animate;
	text.getString.to!int.should.be.greaterThan(0).because("The number should have been upped.");
	assert(!animation.done, "The animation did not yet reach its target and should be not done.");
}

unittest
{
	import fluent.asserts;
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.setFont = infoFont;
	text.setString = "1";
	auto animation = new CountAnimation(text, 1, 0);
	animation.animate;
	text.getString.to!int.should.equal(0).because("The number should have been downed.");
	assert(animation.done, "The animation reached its target and should be done.");
}

unittest
{
	import fluent.asserts;
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.setFont = infoFont;
	text.setString = "1";
	auto animation = new CountAnimation(text, 1000, 0);
	animation.animate;
	text.getString.to!int.should.be.lessThan(1000).because("The number should have been downed.");
	text.getString.to!int.should.be.greaterThan(0).because("The number should not yet be 0.");
	assert(!animation.done, "The animation did not yet reach its target and should be not done.");
}

unittest
{
	import fluent.asserts;
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.setFont = infoFont;
	text.setString = "0";
	auto animation = new CountAnimation(text, 0, 1000);
	animation.forceFinish;
	text.getString.to!int.should.equal(1000).because("The number should have been magically upped to the final value.");
	assert(animation.done, "The animation was forced to finish and is therefore done.");
}

unittest
{
	import fluent.asserts;
	import mahjong.graphics.cache.font;
	auto text = new Text;
	text.position = Vector2f(100, 1500);
	text.setFont = infoFont;
	text.setString = "0";
	auto boundsBeforeCounting = text.getGlobalBounds;
	auto animation = new CountAnimation(text, 0, 1000);
	animation.forceFinish;
	auto boundsAfterCounting = text.getGlobalBounds;
	boundsBeforeCounting.top.should.equal(1500).because("The top should not have moved");
	boundsAfterCounting.top.should.equal(1500).because("The top should not have moved");
	(boundsBeforeCounting.left + boundsBeforeCounting.width).should.equal(
		boundsAfterCounting.left + boundsAfterCounting.width).because( 
		"The right of the text should be kept constant as this feels more natural");
}
