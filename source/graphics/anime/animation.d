module mahjong.graphics.anime.animation;

import std.experimental.logger;
import std.range;
import std.uuid;
import mahjong.share.range;

Animation[] animations;

void addUniqueAnimation(Animation anime)
{
	animations.remove!((a,b) => a.objectId == b.objectId)(anime);
	animations ~= anime;
}

class Animation
{
	UUID objectId;
	
	void animate()
	{
		nextFrame;
		if(done)
		{
			trace("Animation (", objectId, ") finished.");
			onAnimationFinished;
			animations.remove!((a,b) => a == b)(this);
		}
	}

	protected bool done;
	
	protected abstract void nextFrame();
	
	void addAftermath(alias effect, Args...)(Args args)
	{
		_effects ~= (){effect(args);};
	}
	
	private void function()[] _effects;
	
	private void onAnimationFinished()
	{
		foreach(eff; _effects)
		{
			eff();
		}
	}
}

class ChainAnimation : Animation
{
	this(Animation[] anime...)
	{
		_animations = anime;
	}
	
	void addAnimation(Animation anime)
	in
	{
		assert(anime !is null);
	}
	body
	{
		_animations ~= anime;
	}
	
	protected override void nextFrame()
	{
		_animations.front.nextFrame;
		if(_animations.front.done)
		{
			_animations.popFront;
			done = _animations.empty;
		}
	}
	
	private Animation[] _animations;
}
