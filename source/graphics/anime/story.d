module mahjong.graphics.anime.story;

import std.array;
import std.experimental.logger;
import mahjong.graphics.anime.animation;

class Storyboard : Animation
{
	this(Animation[] animations)
	{
		_animations = animations;
	}

	private Animation[] _animations;

	override bool done() @property
	{
		return _animations.length == 0;
	}

	protected override void nextFrame()
	{
		_animations.front.animate;
		if(_animations.front.done)
		{
			info("Finished animating ", _animations.front);
			_animations = _animations[1..$];
		}
	}

	protected override void finishNow() 
	{
		foreach(animation; _animations)
		{
			animation.forceFinish;
		}
		_animations = null;
	}
}

unittest
{
	import fluent.asserts;
	auto firstAnimation = new DummyAnimation(1);
	auto secondAnimation = new DummyAnimation(1);
	auto storyboard = new Storyboard([firstAnimation, secondAnimation]);
	storyboard.animate;
	firstAnimation.done.should.equal(true).because("The animation supplied first should be handled first");
	secondAnimation.done.should.equal(false).because("The other animation should not be done yet.");
	storyboard.done.should.equal(false).because("The animation supplied first should be handled first");
}

unittest
{
	import fluent.asserts;
	auto innerAnimation = new DummyAnimation(1);
	auto storyboard = new Storyboard([innerAnimation]);
	storyboard.animate;
	storyboard.done.should.equal(true).because("all inner animations have finished");
}

unittest
{
	import fluent.asserts;
	auto firstAnimation = new DummyAnimation(200);
	auto secondAnimation = new DummyAnimation(2400);
	auto storyboard = new Storyboard([firstAnimation, secondAnimation]);
	storyboard.forceFinish;
	firstAnimation.done.should.equal(true).because("all inner animations should be forced to finish");
	secondAnimation.done.should.equal(true).because("all inner animations should be forced to finish");
	storyboard.done.should.equal(true).because("the storyboard itself should be finished.");
}


Animation parallel(Animation[] animations)
{
	return new ParallelAnimation(animations);
}

unittest
{
	import fluent.asserts;
	Animation animationA = new DummyAnimation(1);
	Animation animationB = new DummyAnimation(1);
	auto chainedAnimation = new DummyAnimation(1);
	auto storyboard = new Storyboard([
			[animationA, animationB].parallel,
			chainedAnimation
		]);
	storyboard.animate;
	animationA.done.should.equal(true);
	animationB.done.should.equal(true);
	chainedAnimation.done.should.equal(false);
	storyboard.done.should.equal(false);
	storyboard.animate;
	chainedAnimation.done.should.equal(true);
	storyboard.done.should.equal(true);
}