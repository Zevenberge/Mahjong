module mahjong.graphics.utils;

import dsfml.graphics : Transform, RenderTexture, Vector2u;

Transform unity()
{
	return Transform(1,0,0, 0,1,0, 0,0,1);
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