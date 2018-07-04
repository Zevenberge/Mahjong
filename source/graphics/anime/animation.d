module mahjong.graphics.anime.animation;

import std.algorithm;
import std.experimental.logger;
import std.format;
import std.range;
import std.uuid;
import mahjong.share.range;

class Animation
{
	UUID objectId;
	
	void animate()
	{
		nextFrame;
		if(done)
		{
			onDone;
		}
	}

	void forceFinish()
	out
	{
		// Enforce universal state.
		assert(done, "The animation didn't finish even though it was forced to.");
	}
	body
	{
		finishNow;
		onDone;
	}

	protected void onDone()
	{
		trace("Animation (", objectId, ") finished.");
		_animations.remove!((a,b) => a == b)(this);
	}

	abstract bool done() @property;
	
	protected abstract void nextFrame();
	protected abstract void finishNow();
}

unittest
{
	auto dummyAnimation = new DummyAnimation(1);
	dummyAnimation.animate;
	assert(dummyAnimation.done, "The animation should be done.");
}

unittest
{
	auto dummyAnimation = new DummyAnimation(1);
	_animations = [dummyAnimation];
	dummyAnimation.animate;
	assert(_animations.length == 0, "The finished animation should be removed from the stack");
	_animations = null;
}

unittest
{
	auto dummyAnimation = new DummyAnimation(420);
	_animations = [dummyAnimation];
	dummyAnimation.forceFinish;
	assert(_animations.length == 0, "The dummy animation should have removed itself from the array after being forced to finish");
}

void addAnimation(Animation anime)
{
	_animations ~= anime;
}

unittest
{
	import fluent.asserts;
	auto anime = new DummyAnimation(1);
	addAnimation(anime);
	_animations.should.equal([anime]);
	_animations = null;
}

void addUniqueAnimation(Animation anime)
{
	_animations.remove!((a,b) => a.objectId == b.objectId)(anime);
	_animations ~= anime;
}

unittest
{
	import fluent.asserts;
	auto objectId = randomUUID;
	auto dummyAnimation1 = new DummyAnimation(1);
	dummyAnimation1.objectId = objectId;
	addUniqueAnimation(dummyAnimation1);
	_animations.should.equal([dummyAnimation1]).because("The animation should have been added");
	_animations = null;
}

unittest
{
	auto objectId = randomUUID;
	auto dummyAnimation1 = new DummyAnimation(1);
	dummyAnimation1.objectId = objectId;
	auto dummyAnimation2 = new DummyAnimation(1);
	dummyAnimation2.objectId = objectId;
	_animations = [dummyAnimation1];
	addUniqueAnimation(dummyAnimation2);
	assert(_animations.length == 1, "There should be only one surviving animation");
	assert(_animations[0] == dummyAnimation2, "The first should be swapped with the second");
	assert(_animations[0] != dummyAnimation1, "The first should have been killed");
	_animations = null;
}

void addIfNonExistent(Animation anime)
{
	if(_animations.filter!(a => a.objectId == anime.objectId).empty)
	{
		trace("Added animation (", anime.objectId, ") to the list");
		_animations ~= anime;
	}
}

unittest
{
	auto objectId = randomUUID;
	auto dummyAnimation1 = new DummyAnimation(1);
	dummyAnimation1.objectId = objectId;
	addIfNonExistent(dummyAnimation1);
	assert(_animations == [dummyAnimation1], "The animation should have been added");
	_animations = null;
}

unittest
{
	auto objectId = randomUUID;
	auto dummyAnimation1 = new DummyAnimation(1);
	dummyAnimation1.objectId = objectId;
	auto dummyAnimation2 = new DummyAnimation(1);
	dummyAnimation2.objectId = objectId;
	_animations = [dummyAnimation1];
	addIfNonExistent(dummyAnimation2);
	assert(_animations.length == 1, "There should be only one surviving animation");
	assert(_animations[0] == dummyAnimation1, "The first should have remained in the array");
	assert(_animations[0] != dummyAnimation2, "The second should not have been added");
	_animations = null;
}

void animateAllAnimations()
{
	trace("Animating animations");
	foreach(animation; _animations)
	{
		trace("Animating ", animation);
		animation.animate;
	}
}

unittest
{
	auto dummyAnimation1 = new DummyAnimation(1);
	auto dummyAnimation2 = new DummyAnimation(2);
	_animations = [dummyAnimation1, dummyAnimation2];
	animateAllAnimations;
	assert(dummyAnimation1.done, "The first animation should be finished");
	assert(dummyAnimation2.amountOfFrames == 1, "The second animation still has a frame left");
	assert(_animations == [dummyAnimation2], "The completed animations should have been removed");
	_animations = null;
}

private Animation[] _animations;

version(unittest)
{
	class DummyAnimation : Animation
	{
		this(int amountOfFrames)
		{
			this.amountOfFrames = amountOfFrames;
		}

		int amountOfFrames;

		override protected void nextFrame() 
		{
			--amountOfFrames;
		}

		override protected void finishNow() 
		{
			amountOfFrames = 0;
		}

		override bool done() 
		{
			return amountOfFrames == 0;
		}
	}
}

class ParallelAnimation : Animation
{
	// Array instead of varargs https://issues.dlang.org/show_bug.cgi?id=17504
	this(Animation[] animations)
	{
		_animations = animations;
	}

	private Animation[] _animations;

	protected override void nextFrame()
	{
		_animations.filter!(a => !a.done).each!(a => a.animate);
	}

	protected override void finishNow() 
	{
		_animations.each!(a => a.forceFinish);
	}

	protected override bool done() @property
	{
		return _animations.all!(a => a.done);
	}

	override string toString() 
	{
		return "%s: %s".format(super.toString(), _animations);
	}
}

unittest
{
	Animation animationA = new DummyAnimation(1);
	Animation animationB = new DummyAnimation(1);
	auto parallelAnimation = new ParallelAnimation([animationA, animationB]);
	parallelAnimation.animate;
	assert(animationA.done, "The first wrapped animation should be done");
	assert(animationB.done, "The second wrapped animation should be done");
	assert(parallelAnimation.done, "The parallel animation should be done");
}
unittest
{
	Animation animationA = new DummyAnimation(1);
	Animation animationB = new DummyAnimation(2);
	auto parallelAnimation = new ParallelAnimation([animationA, animationB]);
	parallelAnimation.animate;
	assert(!parallelAnimation.done, "One of the inner animations is not finished so the parallel animation is not either.");
}

unittest
{
	Animation animationA = new DummyAnimation(100);
	Animation animationB = new DummyAnimation(200);
	auto parallelAnimation = new ParallelAnimation([animationA, animationB]);
	parallelAnimation.forceFinish;
	// Implicit assert check in the out-contract
}

unittest
{
	import fluent.asserts;
	Animation shortAnimation = new DummyAnimation(1);
	Animation longAnimation = new DummyAnimation(2);
	auto parallelAnimation = new ParallelAnimation([shortAnimation, longAnimation]);
	parallelAnimation.animate;
	// Animate the parallel animation a second time. It should only animate the second animation, which is not yet done.
	parallelAnimation.animate;
	parallelAnimation.done.should.equal(true);
}