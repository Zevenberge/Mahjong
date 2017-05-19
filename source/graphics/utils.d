module mahjong.graphics.utils;

import dsfml.graphics.transform;

Transform unity()
{
	return Transform(1,0,0, 0,1,0, 0,0,1);
}

void correctOutOfBounds(ref size_t position, size_t bounds)
out
{
	assert(position >= 0);
	assert(position < bounds);
}
body
{
	if(position < 0)
	{
		position = 0;
	}
	else if(position >= bounds)
	{
		position = bounds - 1;
	}
}