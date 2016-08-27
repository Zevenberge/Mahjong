module mahjong.share.range;

import std.experimental.logger;

void remove(alias pred, T)(ref T[] array, T element)
{
    foreach(i, e; array)
    {
        if(pred(e, element))
        {
            array = array[0 .. i] ~ array [i+1..$];
            return;
        }
    }
}