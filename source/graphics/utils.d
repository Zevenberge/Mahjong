module mahjong.graphics.utils;

import dsfml.graphics.transform;

Transform unity()
{
	return Transform(1,0,0, 0,1,0, 0,0,1);
}

void correctOutOfBounds(ref int position, ulong bounds)
in
{
   assert(bounds < int.max);
}
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
    position = cast(int)bounds - 1;
  }
}