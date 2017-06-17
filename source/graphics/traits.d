module mahjong.graphics.traits;

import dsfml.system.vector2;
import mahjong.graphics.drawing.tile;

template hasGlobalBounds(S)
{
	enum bool hasGlobalBounds = 
		__traits(compiles, (S.init).getGlobalBounds);
}

template hasFloatPosition(S)
{
	enum bool hasFloatPosition = 
		__traits(compiles, (S.init).position(Vector2f(0,0)));
}

unittest
{
	class NoPosition
	{
	}
	assert(!hasFloatPosition!NoPosition, "If no position is defined, it cannot have a float position");
}

unittest
{
	class IntPosition
	{
		Vector2i position(Vector2i newPosition) @property
		{
			return newPosition;
		}
	}
	assert(!hasFloatPosition!IntPosition, "An int position is no float position");
}

unittest
{
	class FloatPosition
	{
		Vector2f position(Vector2f newPosition) @property
		{
			return newPosition;
		}
	}
	assert(hasFloatPosition!FloatPosition, "A float position setter is provided and the template should return true");
}