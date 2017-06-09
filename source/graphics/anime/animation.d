module mahjong.graphics.anime.animation;

import std.algorithm.iteration;
import std.experimental.logger;
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
			trace("Animation (", objectId, ") finished.");
			_animations.remove!((a,b) => a == b)(this);
		}
	}

	protected abstract bool done() @property;
	
	protected abstract void nextFrame();
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

void addUniqueAnimation(Animation anime)
{
	_animations.remove!((a,b) => a.objectId == b.objectId)(anime);
	_animations ~= anime;
}

unittest
{
	auto objectId = randomUUID;
	auto dummyAnimation1 = new DummyAnimation(1);
	dummyAnimation1.objectId = objectId;
	addUniqueAnimation(dummyAnimation1);
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
	foreach(animation; _animations)
	{
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

		override protected bool done() 
		{
			return amountOfFrames == 0;
		}
	}
}

template Chain(TAnimation : Animation)
{
	class Chain : TAnimation
	{
		this(Args...)(Animation inner, Args args)
		in
		{
			assert(inner !is null, "The root of the chain should not be a chain animation");
		}
		body
		{
			super(args);
			_inner = inner;
		}

		private Animation _inner;

		override void animate()
		{
			if(_inner.done)
			{
				super.animate;
			}
			else
			{
				_inner.animate;
			}
		}

		override protected bool done() @property
		{
			return _inner.done && super.done;
		}
	}
}

unittest
{
	auto innerAnimation = new DummyAnimation(1);
	auto chainAnimation = new Chain!DummyAnimation(innerAnimation, 1);
	chainAnimation.animate;
	assert(innerAnimation.done, "The inner animation should be handled first");
	assert(!chainAnimation.done, "The outer animation should not be done yet.");
}

unittest
{
	auto innerAnimation = new DummyAnimation(0);
	auto chainAnimation = new Chain!DummyAnimation(innerAnimation, 1);
	chainAnimation.animate;
	assert(chainAnimation.done, "The chain animation should be done.");
}

unittest
{
	auto innerAnimation = new DummyAnimation(1);
	auto chainAnimation = new Chain!DummyAnimation(innerAnimation, 1);
	_animations = [chainAnimation];
	chainAnimation.animate;
	assert(_animations == [chainAnimation], "Even though the inner animation finished, the outher should not have been removed");
	_animations = null;
}