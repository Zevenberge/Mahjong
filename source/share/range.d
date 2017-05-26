module mahjong.share.range;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.range;

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

template without(alias equality)
{
	T[] without(T)(T[] arr, T[] exclusion)
	{
		return arr.filter!(elem => !exclusion.any!(excl => equality(excl, elem))).array;
	}
}

template first(alias pred)
{
	auto first(Range)(Range range) if(isInputRange!Range)
	{
		auto foundRange = range.find!pred;
		if(foundRange.empty) return (ElementType!Range).init;
		return foundRange.front;
	}
}

size_t indexOf(Range, E)(Range range, E element) if(isInputRange!Range)
{
	return range.countUntil!(e => e == element);
}