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
	
	
	protected override void nextFrame()
	{
		_amountOfFrames--;
		if(_amountOfFrames == 0)
		{
			done = true;
		}
	}
	
	private int _amountOfFrames;
}