module mahjong.util.range;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.math;
import std.range;
import std.traits;

template max(alias pred, TReturn)
{
	auto max(Range)(Range range) if (isInputRange!Range && isNumeric!TReturn)
	{
		auto myMax = TReturn.init;
		foreach (element; range)
		{
			auto value = pred(element);
			if (value > myMax)
			{
				myMax = value;
			}
			static if (isFloatingPoint!TReturn)
			{
				if (myMax.isNaN)
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
	assert([0, 1, 2, 3, 4, 5].max!(s => s % 5, int) == 4,
			"It takes the max of the evaluated expression");
	assert([0f, 1f, 2f, 3f, 4f, 5f].max!(s => s % 5, float) == 4, "It should work for floats");
	assert([0f, 1f, 2f, 3f, float.nan, 5f].max!(s => s % 5, float) == 3,
			"The max function should ignore NaN");
	assert([0f, 3f, 2f, float.nan, 1f, 5f].max!(s => s % 5, float) == 3,
			"The max function is independent on order");
}

template without(alias equality = (a, b) => a == b)
{
	T[] without(T)(T[] arr, T[] exclusion)
	{
		return arr.filter!(elem => !exclusion.any!(excl => equality(excl, elem))).array;
	}
}

template first(alias pred)
{
	auto first(Range)(Range range) if (isInputRange!Range)
	{
		auto foundRange = range.find!pred;
		if (foundRange.empty)
			return (ElementType!Range).init;
		return foundRange.front;
	}
}

size_t indexOf(Range, E)(Range range, E element) if (isInputRange!Range)
{
	return range.countUntil!(e => e is element);
}

unittest
{
}

T[] insertAt(T)(T[] collection, T element, size_t index)
{
	T[] placeholder;
	if (index != 0)
	{
		placeholder ~= collection[0 .. index];
	}
	placeholder ~= element;
	if (index != collection.length)
	{
		placeholder ~= collection[index .. $];
	}
	collection = placeholder;
	return placeholder;
}

unittest
{
	assert([0, 1, 2] == [1, 2].insertAt(0, 0), "New element should be inserted at 0");
	assert([1, 0, 2] == [1, 2].insertAt(0, 1), "New element should be inserted at 1");
	assert([1, 2, 0] == [1, 2].insertAt(0, 2), "New element should be inserted at 2");
}

template sum(fun...) if (fun.length >= 1)
{
	alias yeOldeSum = std.algorithm.sum;
	auto sum(Range)(Range range) if (isInputRange!(Unqual!Range))
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
	auto flatMap(Range)(Range range) if (isInputRange!Range)
	{
		auto mappedResult = range.map!fun;
		alias E = ElementType!(typeof(mappedResult));
		static if(isMutable!(ElementType!E))
		{
			return mappedResult.joiner;
		}
		else static if(isArray!E)
		{
			return mappedResult.map!(x => x[]).joiner;
		}
		else
		{
			static assert(false, "Cannot join a range of immutable ranges.");
		}
	}
}

unittest
{
	struct Bubble
	{
		int[] ints;
	}

	auto flattened = [Bubble([1, 2]), Bubble([3, 4])].flatMap!(x => x.ints).array;
	assert([1, 2, 3, 4].equal(flattened), "The two arrays should be joined");
}

unittest
{
	struct Bubble
	{
		int[] ints;
	}

	Bubble[] bubbles; // Empty range;
	auto flattened = bubbles.flatMap!(x => x.ints).array;
	assert(flattened.length == 0,
			"Flat-mapping an empty range should return an empty range of the result type");
}

unittest
{
	import std.range : iota;
	import fluent.asserts;

	struct Counter
	{
		auto oneTwoThree()
		{
			return iota(1, 4);
		}
	}

	auto counters = [Counter(), Counter(), Counter()].flatMap!(c => c.oneTwoThree);
	counters.should.equal([1, 2, 3, 1, 2, 3, 1, 2, 3]);
}

@("Can I flatMap a range of constant objects?")
unittest
{
	struct Bubble
	{
		const(int)[] ints;
	}

	auto flattened = [Bubble([1, 2]), Bubble([3, 4])].flatMap!(x => x.ints).array;
	assert([1, 2, 3, 4].equal(flattened), "The two arrays should be joined");
}

@("Can I flatMap a range of constant arrays?")
unittest
{
	struct Bubble
	{
		const(int[]) ints;
	}

	auto flattened = [Bubble([1, 2]), Bubble([3, 4])].flatMap!(x => x.ints).array;
	assert([1, 2, 3, 4].equal(flattened), "The two arrays should be joined");
}

template atLeastOneUntil()
{
	struct Result(Range, Needle)
	{
		this(Range range, Needle needle)
		{
			_range = range;
			_needle = needle;
			_isOnePassed = false;
		}

		private Range _range;
		private Needle _needle;
		private bool _isOnePassed;

		Needle front()
		{
			return _range.front;
		}

		void popFront()
		{
			assert(!empty);
			_isOnePassed = true;
			_range.popFront;
		}

		bool empty()
		{
			if(_range.empty) return true;
			return _isOnePassed && _range.front is _needle;
		}
	}

	auto atLeastOneUntil(Range, Needle)(Range range, Needle needle)
	{
		static assert(isInputRange!Range,
				"An input range should be supplied instead of " ~ Range.stringof);
		return Result!(Range, Needle)(range, needle);
	}
}

unittest
{
	import fluent.asserts;

	[4, 5, 4].atLeastOneUntil(4).should.equal([4, 5]);
}

import std.typecons : Tuple;
private Tuple!(int, double) __HACK__;