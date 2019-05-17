module mahjong.util.collections;

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

struct NoGcArray(size_t maxSize, T)
{
    private T[maxSize] _buffer;
    private size_t _length;
    size_t length() pure const @nogc nothrow
    {
        return _length;
    } 

    void opOpAssign(string op)(T element) pure @nogc nothrow
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

    T opIndex(size_t index)
    in(index < _length, "Cannot access index greater than length")
    {
        return _buffer[index];
    }

    private size_t _index;

    T front() pure @nogc nothrow
    {
        return this[_index];
    }

    void popFront() pure @nogc nothrow
    {
        _index++;
    }

    bool empty() pure @nogc nothrow
    {
        return _length <= _index;
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