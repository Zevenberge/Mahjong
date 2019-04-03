module mahjong.graphics.anime.idle;

import mahjong.graphics.anime.animation;

class Idle : Animation
{
	this(int amountOfFrames)
	in
	{
		assert(amountOfFrames > 0, "Duration should be larger than 0.");
	}
	body
	{
		_amountOfFrames = amountOfFrames;
	}

	protected override void finishNow() 
	{
		_amountOfFrames = 0;
	}

	protected override void nextFrame()
	{
		_amountOfFrames--;
	}

	protected override bool done()
	{
		return _amountOfFrames == 0;
	}
	
	private int _amountOfFrames;
}

unittest
{
	auto idle = new Idle(100);
	assert(!idle.done);
	idle.nextFrame;
	assert(!idle.done);
	idle.finishNow;
	assert(idle.done);
}