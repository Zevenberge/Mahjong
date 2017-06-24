module mahjong.graphics.coords;

import std.math;
import std.traits;
import dsfml.system.vector2;
import dsfml.graphics.transformable;

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
	
	bool opEquals()(auto ref Coords!T other) const
	{
		return (x - other.x).abs < 0.001 && (y - other.y).abs < 0.001 &&
			(rotation - other.rotation).abs < 0.001;
	}

	string toString() const
	{
		import std.conv;
		return "X: " ~ x.text ~ " Y: " ~ y.text ~ " R: " ~ rotation.text;
	}
}

unittest
{
	import fluent.asserts;
	auto coords = FloatCoords(1,2,3);
	coords.move(Vector2f(4,6));
	coords.position.should.equal(Vector2f(5, 8));
}

FloatCoords getFloatCoords(Transformable t)
{
	return FloatCoords(t.position, t.rotation);
}

void setFloatCoords(Transformable t, FloatCoords c)
{
	t.rotation = c.rotation;
	t.position = c.position;
}
