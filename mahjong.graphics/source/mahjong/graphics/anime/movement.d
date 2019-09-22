module mahjong.graphics.anime.movement;

import std.experimental.logger;
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
		_finalCoords = finalCoords;
		_amountOfFrames = amountOfFrames;
		_transformable = transformable;
		auto pos = _transformable.position;
		auto rot = _transformable.rotation;
		_deltaCoords = FloatCoords(
			calculateDelta(pos.x, finalCoords.x),
			calculateDelta(pos.y, finalCoords.y),
			calculateRotationPerFrame(rot, finalCoords.rotation)
			);
	}
	
	protected override void nextFrame()
	{
		trace("Moving ", _deltaCoords.position);
		_transformable.position = _transformable.position + _deltaCoords.position;
		_transformable.rotation = _transformable.rotation + _deltaCoords.rotation;
		_amountOfFrames--;
	}

	protected override void finishNow() 
	{
		_transformable.position = _finalCoords.position;
		_transformable.rotation = _finalCoords.rotation;
		_amountOfFrames = 0;
	}

	protected override bool done()
	{
		return _amountOfFrames == 0;
	}

	private:
		Transformable _transformable;
		FloatCoords _deltaCoords;
		FloatCoords _finalCoords;
		int _amountOfFrames;
		
		float calculateDelta(float init, float target)
		{
			return (target - init)/_amountOfFrames;
		}

		float calculateRotationPerFrame(float init, float target)
		{
			import std.math : abs;
			if(init - target > 180f)
			{
				return calculateDelta(init - 360f, target);
			}
			else if(target - init > 180f)
			{
				return calculateDelta(init, target - 360f);
			}
			else
			{
				return calculateDelta(init, target);
			}
		}

}

unittest
{
	auto shape = new RectangleShape;
	auto animation = new MovementAnimation(shape, FloatCoords(500, 400, 90), 2);
	animation.animate;
	auto coords = FloatCoords(shape.position, shape.rotation);
	assert(coords == FloatCoords(250, 200, 45), "The movement is half-way");
	animation.animate;
	coords = FloatCoords(shape.position, shape.rotation);
	assert(coords == FloatCoords(500, 400, 90), "The movement is done");
	assert(animation.done, "The animation is done");
}

unittest
{
	auto shape = new RectangleShape;
	auto animation = new MovementAnimation(shape, FloatCoords(500, 400, 90), 500);
	animation.forceFinish;
	auto coords = FloatCoords(shape.position, shape.rotation);
	assert(coords == FloatCoords(500, 400, 90), "The movement is done after a forced finish");
}

@("A rotation is in the direction of least change")
unittest
{
	import fluent.asserts;
	auto shape = new RectangleShape;
	auto animation = new MovementAnimation(shape, FloatCoords(500, 400, 270), 2);
	animation.animate;
	shape.rotation.should.be.approximately(315f, 0.1f);
}

@("When the element is almost fully rotated, it understands its orientation")
unittest
{
	import fluent.asserts;
	auto shape = new RectangleShape;
	shape.rotation = 359.9f;
	auto animation = new MovementAnimation(shape, FloatCoords(500, 400, 90), 2);
	animation.animate;
	shape.rotation.should.be.approximately(45f, 0.1f);
}

@("A animation over three frames is still accurate direction wise")
unittest
{
	import fluent.asserts;
	auto shape = new RectangleShape;
	shape.rotation = 359.9f;
	auto animation = new MovementAnimation(shape, FloatCoords(500, 400, 90), 3);
	animation.animate;
	shape.rotation.should.be.approximately(30f, 0.1f);
}