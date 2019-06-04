module mahjong.util.collections;

import std.range.primitives;
import std.typecons;
import mahjong.util.traits;

struct Set(T)
{
    private bool[T] _items;

    void opOpAssign(string op)(T element)
    {
        static if(op == "~")
        {
            _items[element] = true;
        }
        else
        {
            static assert(false, "Only concatenation supported");
        }
    }

    auto values()
    {
        return _items.keys;
    }

    alias values this;
}

@("If I add the same element to a set twice, it still only has one element")
unittest
{
    import fluent.asserts;
    Set!int numbers;
    numbers ~= 42;
    numbers ~= 42;
    numbers.values.should.equal([42]);
}

auto array(size_t size, Range)(Range range) pure @nogc nothrow
    if(isInputRange!Range)
{
    alias E = ElementType!Range;
    NoGcArray!(size, E) arr;
    foreach(element; range) 
    {
        arr ~= element;
    }
    return arr;
}

@("Can I convert a range to a nogc array")
unittest
{
    import std.algorithm : map;
    import fluent.asserts;
    auto original = [1, 2, 3];
    auto result = original.map!(x => x*2).array!(4);
    result.length.should.equal(3);
    result[0].should.equal(2);
    result[1].should.equal(4);
    result[2].should.equal(6);
}

struct NoGcArray(size_t maxSize, T)
{
    static if(isClass!T && isConst!T)
    {
        private Rebindable!T[maxSize] _buffer;
    }
    else
    {
        private T[maxSize] _buffer;
    }

    private size_t _length;
    size_t length() @safe pure const @nogc nothrow
    {
        return _length;
    }
    alias opDollar = length;

    void opOpAssign(string op)(T element) @safe pure @nogc nothrow
    in(_length < maxSize, "Cannot append if the buffer is fully filled.")
    {
        static if(op == "~")
        {
            _buffer[_length] = element;
            ++_length;
        }
        else
        {
            static assert(false, "Only concatenation supported");
        }
    }

    inout(T) opIndex(size_t index) inout @safe pure @nogc nothrow
    in(index < _length, "Cannot access index greater than length")
    {
        return _buffer[index];
    }

    private size_t _index;

    T front() @safe pure @nogc nothrow
    {
        return this[_index];
    }

    void popFront() @safe pure @nogc nothrow
    {
        _index++;
    }

    bool empty() @safe pure @nogc nothrow
    {
        return _length <= _index;
    }

    void sort(alias pred = "a < b")() pure @nogc nothrow
    {
        import std.algorithm : sort;
        auto slice = _buffer[0.. _length];
        slice.sort!pred; 
    }

    static if(isClass!T)
    {
        void remove(T element) @safe pure @nogc nothrow
        {
            auto length = _length;
            auto found = false;
            for(size_t i = 0; i < length; ++i)
            {
                if(found)
                { // Cannot be triggered in the first loop.
                    _buffer[i-1] = _buffer[i];
                    _buffer[i] = null; // Clean up nicely, but can be optimised away.
                }
                else if(_buffer[i] is element)
                {
                    found = true;
                    _length--;
                }
            }
        }

        void remove(Range)(Range range) @safe pure @nogc nothrow
            if(isInputRange!Range && is(ElementType!Range : T))
        {
            foreach(e; range) remove(e);
        }
    }
}

@("Is a no gc array initialised empty?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array.length.should.equal(0);
}

@("Can I add to a no gc array")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array ~= 42;
    array.length.should.equal(1);
    array[0].should.equal(42);
}

@("Can I append two elements to a no gc array?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array ~= 42;
    array ~= 420;
    array.length.should.equal(2);
    array[0].should.equal(42);
    array[1].should.equal(420);
}

@("Can I append beyond max size?")
unittest
{
    import fluent.asserts;
    NoGcArray!(1, int) array;
    array ~= 4;
    (array ~= 420).should.throwSomething;
}

@("Can I ask for elements outside of the length?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, int) array;
    (array[0]).should.throwSomething;
}

@("Can I use algorithm functions on a no gc array")
unittest
{
    import std.algorithm : sum;
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array.sum.should.equal(0);
    array ~= 420;
    array ~= 42;
    array.sum.should.equal(462);
}

@("Is the length of the no gc array walked correctly")
unittest
{
    import std.range : walkLength;
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array.walkLength.should.equal(0);
    array ~= 42;
    array.walkLength.should.equal(1);
}

@("Does chaining stuff work correctly?")
unittest
{
    import std.algorithm : sum, map;
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array ~= 420;
    array ~= 42;
    array.map!(x => x*2).sum.should.equal(924);
}

@("An operation should not be destructive")
unittest
{
    import std.algorithm : sum, map;
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array ~= 420;
    array ~= 42;
    array.map!(x => x*2).sum.should.equal(924);
    array.map!(x => x*2).sum.should.equal(924);
}

@("Can I remove an element from an array?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, Object) array;
    auto removed = new Object;
    array ~= removed;
    array.remove(removed);
    array.length.should.equal(0);
}

@("Are other elements preserved?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, Object) array;
    auto remainer = new Object;
    auto removed = new Object;
    array ~= remainer;
    array ~= removed;
    array.remove(removed);
    array.length.should.equal(1);
    array[0].should.equal(remainer);
}

@("Can I remove a range of elements")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, Object) array;
    auto remainer = new Object;
    auto removed = new Object;
    array ~= remainer;
    array ~= removed;
    array.remove([removed]);
    array.length.should.equal(1);
    array[0].should.equal(remainer);
}

@("Can I manipulate a mutable array of const objects?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, const Object) array;
    auto removed = new Object;
    array ~= removed;
    array.remove(removed);
    array.length.should.equal(0);
}

@("Can I sort a nogc array?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array ~= 42;
    array ~= 1;
    array ~= 420;
    array ~= 100;
    array.sort;
    array[0].should.equal(1);
    array[1].should.equal(42);
    array[2].should.equal(100);
    array[3].should.equal(420);
}

@("Can I sort a nogc array with empty elements?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array ~= 42;
    array ~= 1;
    array ~= 420;
    array.sort;
    array[0].should.equal(1);
    array[1].should.equal(42);
    array[2].should.equal(420);
}

auto allocate(Array)(auto ref inout Array array) pure nothrow
{
    import std.traits : ReturnType;
    alias T = ReturnType!(Array.init.opIndex);
    T[] allocated;
    if(array.length == 0) return allocated;
    foreach(i; 0 .. array.length)
    {
        allocated ~= array[i];
    }
    return allocated;
}

@("Can I allocate an empty array?")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, const Object) array;
    auto allocated = array.allocate;
    allocated.length.should.equal(0);
}

@("Can I retain my elemants on a not empty array")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, Object) array;
    auto contents = new Object;
    array ~= contents;
    auto allocated = array.allocate;
    allocated.length.should.equal(1);
    allocated[0].should.equal(contents);
}

@("Can I allocate an array with primitives")
unittest
{
    import fluent.asserts;
    NoGcArray!(4, int) array;
    array ~= 42;
    auto allocated = array.allocate;
    allocated.length.should.equal(1);
    allocated[0].should.equal(42);
}