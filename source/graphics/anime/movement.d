module mahjong.graphics.anime.movement;

import dsfml.graphics;
import mahjong.graphics.anime.animation;
import mahjong.graphics.coords;

class MovementAnimation : Animation
{
	this(Transformable transformable, FloatCoords finalCoords, int amountOfFrames)
	in
	{
		assert(amountOfFrames > 0, "Amount of frames should be larger than 0");
	}
	body
	{
		_amountOfFrames = amountOfFrames;
		_transformable = transformable;
		auto pos = _transformable.position;
		auto rot = _transformable.rotation;
		_deltaCoords = FloatCoords(
			calculateDelta(pos.x, finalCoords.x),
			calculateDelta(pos.y, finalCoords.y),
			calculateDelta(rot, finalCoords.rotation)
			);
	}
	
	protected override void nextFrame()
	{
		_transformable.position += _deltaCoords.position;
		_transformable.rotation = _transformable.rotation + _deltaCoords.rotation;
		_amountOfFrames--;
		if(_amountOfFrames == 0)
		{
			done = true;
		}
	}
	
	private:
		Transformable _transformable;
		FloatCoords _deltaCoords;
		int _amountOfFrames;
		
		float calculateDelta(float init, float target)
		{
			return (target - init)/_amountOfFrames;
		}

}