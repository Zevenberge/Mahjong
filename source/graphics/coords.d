module mahjong.graphics.coords;

import dsfml.system.vector2;

alias FloatCoords = Coords!float;
alias IntCoords = Coords!int;

struct Coords(T)
{
	T x;
	T y;
	float rotation;
	
	Vector2!T vector() @property
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