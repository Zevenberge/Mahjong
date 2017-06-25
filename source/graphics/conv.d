module mahjong.graphics.conv;

import std.conv;
import std.math;
import dsfml.graphics;
import mahjong.graphics.enums.kanji;

void setSize(Sprite sprite, Vector2f size)
{
	setSize(sprite, size.x, size.y);
}

void setSize(Sprite sprite, float x, float y = -1)
out
{
	FloatRect size = sprite.getGlobalBounds();
	assert(abs(size.width - x) < 1); 
	if(y > 0)
	{
		assert(abs(size.height - y) < 1); 
	}
}
body
{
	FloatRect size = sprite.getGlobalBounds();
	Vector2f scale0 = sprite.scale;
	float scale_x = x/size.width;
	if(y > 0)
	{
		float scale_y = y/size.height;
		sprite.scale = Vector2f(scale0.x * scale_x,scale0.y * scale_y);
	}
	else
	{
		sprite.scale = Vector2f(scale0.x * scale_x,scale0.x * scale_x);
	}
}

unittest
{
	auto sprite = new Sprite;
	sprite.textureRect = IntRect(10, 20, 30, 40);
	sprite.setSize(60);
	assert(sprite.scale == Vector2f(2, 2), "The scale should be universally doubled");
	assert(sprite.getGlobalBounds.size == Vector2f(60, 80), "The size should be universally doubled");
}

unittest
{
	auto sprite = new Sprite;
	sprite.textureRect = IntRect(10, 20, 30, 40);
	sprite.setSize(60, 120);
	assert(sprite.scale == Vector2f(2, 3), "The scale should differ from x and y");
	assert(sprite.getGlobalBounds.size == Vector2f(60, 120), "The size should be the supplied size");
}

Vector2i toVector2i(Vector2f v)
{
	return Vector2i(v.x.to!int, v.y.to!int);
}

Vector2f toVector2f(Vector2i v)
{
	return Vector2f(v.x, v.y);
}

float toRadians(float rotation)
{
	enum factor = PI/180.;
	return rotation * factor;
}

string toKanji(uint number)
{
	char[] builder;
	do
	{
		auto digit = number - floor(number/10.)*10;
		builder = digit.to!Numbers.to!string  ~ builder;
		number /= 10;
	}
	while(number > 0);
	return builder.to!string;
}

IntRect toRect(const Vector2i v) pure
{
	return IntRect(0,0, v.x, v.y);
}

FloatRect toRect(const Vector2f v) pure
{
	return FloatRect(0, 0, v.x, v.y);
}

Vector2f size(const FloatRect rect) @property pure 
{
	return Vector2f(rect.width, rect.height);
}

Vector2f position(const FloatRect rect) @property pure
{
	return Vector2f(rect.left, rect.top);
}