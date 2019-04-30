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