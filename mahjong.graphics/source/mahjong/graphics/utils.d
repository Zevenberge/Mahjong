module mahjong.graphics.utils;

import dsfml.graphics : Transform, RenderTexture, Vector2u, Vector2f, Vector2;
import mahjong.graphics.opts : styleOpts;

Transform unity()
{
	return Transform(1,0,0, 0,1,0, 0,0,1);
}

Transform rotationAroundCenter(float rotation)
{
    auto center = styleOpts.center;
    auto transform = unity;
    transform.rotate(rotation, center.x, center.y);
    return transform;
}

void correctOutOfBounds(ref size_t position, size_t length)
out
{
	assert(position < length);
}
body
{
	if(position >= length)
	{
		position = length - 1;
	}
}

unittest
{
	import fluent.asserts;
	size_t position = 5;
	correctOutOfBounds(position, 7);
	position.should.equal(5).because("within the bounds, the position should not have been corrected");
}

unittest
{
	import fluent.asserts;
	size_t position = 5;
	correctOutOfBounds(position, 4);
	position.should.equal(3).because("out of the bounds, the position should be place to the last element");
}

RenderTexture freeze(alias drawingFun)(Vector2u size)
{
	auto texture = new RenderTexture;
	texture.create(size.x, size.y);
	drawingFun(texture);
	texture.display;
	return texture;
}

template length(T)
{
	float length(const Vector2!T vector) pure @property
	{
		import std.math;
		return sqrt(vector.x * vector.x + vector.y * vector.y);
	}
}

unittest
{
	import fluent.asserts;
	Vector2f(0,0).length.should.equal(0f);
	Vector2f(1,0).length.should.equal(1f);
	Vector2f(0,1).length.should.equal(1f);
	Vector2f(3,4).length.should.equal(5f);
}

template normalized(T)
{
	Vector2!T normalized(const Vector2!T initialVector) pure @property
	{
		auto size = initialVector.length;
		if(size == 0) return Vector2!T(0,0);
		return initialVector / size;
	}
}

unittest
{
	import fluent.asserts;
	auto zeroVector = Vector2f(0,0);
	zeroVector.normalized.should.equal(Vector2f(0,0));
}
unittest
{
	import fluent.asserts;
	import std.math;
	auto vector = Vector2f(100, 100);
	vector.normalized.should.equal(Vector2f(1,1)*SQRT1_2);
}