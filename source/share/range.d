module mahjong.share.range;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.math;
import std.range;
import std.traits;

template max(alias pred, TReturn)
{
	auto max(Range)(Range range) 
		if(isInputRange!Range && isNumeric!TReturn)
	{
		auto myMax = TReturn.init;
		foreach(element; range)
		{
			auto value = pred(element);
			if(value > myMax)
			{
				myMax = value;
			}
			static if(isFloatingPoint!TReturn)
			{
				if(myMax.isNaN)
				{
					myMax = value;
				}
			}
		}
		return myMax;
	}
}
unittest
{
	assert([0,1,2,3,4,5].max!(s => s % 5, int) == 4, "It takes the max of the evaluated expression");
	assert([0f,1f,2f,3f,4f,5f].max!(s => s % 5, float) == 4, "It should work for floats");
	assert([0f,1f,2f,3f,float.nan,5f].max!(s => s % 5, float) == 3, "The max function should ignore NaN");
	assert([0f,3f,2f,float.nan,1f,5f].max!(s => s % 5, float) == 3, "The max function is independent on order");
}

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

T[] insertAt(T)(T[] collection, T element, size_t index)
{
	T[] placeholder;
	if(index != 0)
	{
		placeholder ~= collection[0 .. index];
	}
	placeholder ~= element;
	if(index != collection.length)
	{
		placeholder ~= collection[index .. $];
	}
	collection = placeholder;
	return placeholder;
}

unittest
{
	assert([0,1,2] == [1,2].insertAt(0,0), "New element should be inserted at 0");
	assert([1,0,2] == [1,2].insertAt(0,1), "New element should be inserted at 1");
	assert([1,2,0] == [1,2].insertAt(0,2), "New element should be inserted at 2");
}


template sum(fun...) if(fun.length >= 1)
{
	alias yeOldeSum = std.algorithm.sum;
	auto sum(Range)(Range range) if(isInputRange!(Unqual!Range))
	{
		return yeOldeSum(range.map!fun);
	}
}

unittest
{
	struct Wrapper
	{
		int value;
	}

	auto result = [Wrapper(5), Wrapper(18)].sum!(w => w.value);
	assert(result == 23, "The sum should give the sum of the wrapped numbers");
}

template flatMap(alias fun) //if(isInputRange!(ReturnType!fun))
{
	auto flatMap(Range)(Range range) if(isInputRange!Range)
	{
		return .fold!((a,b) => a ~ b)(range.map!(fun));
	}
}

unittest
{
	struct Bubble
	{
		int[] ints;
	}
	auto flattened = [Bubble([1,2]), Bubble([3,4])].flatMap!(x => x.ints).array;
	assert([1, 2, 3, 4].equal(flattened), "The two arrays should be joined");
}