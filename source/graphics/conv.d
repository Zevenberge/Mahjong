module mahjong.graphics.conv;

import std.conv;
import std.math;
import dsfml.graphics;
import mahjong.graphics.enums.kanji;

void pix2scale(Sprite sprite, float x, float y = -1)
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
  /*
   Given a size of x by y pixels, scale the sprite such that it takes this size.
  */
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

FloatRect toRect(Vector2f v)
{
	return FloatRect(0, 0, v.x, v.y);
}

Vector2f size(FloatRect rect) @property
{
	return Vector2f(rect.width, rect.height);
}

Vector2f position(FloatRect rect) @property
{
	return Vector2f(rect.left, rect.top);
}