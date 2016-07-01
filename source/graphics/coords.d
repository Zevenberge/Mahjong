module mahjong.graphics.coords;

import std.traits;
import dsfml.system.vector2;

alias FloatCoords = Coords!float;
alias IntCoords = Coords!int;

struct Coords(T) if(isNumeric!T)
{
	T x = 0;
	T y = 0;
	float rotation = 0;
	
	void move(Vector2!T offSet)
	{
		x += offSet.x;
		y += offSet.y;
	}
	
	Vector2!T position(Vector2!T newVector) @property
	{
		x = newVector.x;
		y = newVector.y;
		return newVector;
	}
	
	Vector2!T position() const @property
	{
		return Vector2!T(x, y);
	}
	
	this(Vector2!T v, float rotation = 0)
	{
		this(v.x, v.y, rotation);
	}
	
	this(T x, T y, float rotation = 0)
	{
		this.x = x;
		this.y = y;
		this.rotation = rotation;
	}
}
