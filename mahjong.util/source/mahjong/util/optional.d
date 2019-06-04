module mahjong.util.optional;

import optional.optional;

public import optional.optional : unwrap;

ref T get(T)(ref Optional!T opt) @trusted @nogc pure nothrow
in(opt != none, "Optional should have contents")
{
    static if(!is(T == class))
    {
        return *opt.unwrap;
    }
    else
    {
        static assert(false, "Use .unwrap instead");
    }
}

@("Do I get the contents?")
unittest
{
    import fluent.asserts;
    auto x = some(42);
    x.get.should.equal(42);
}

@("Can I pass a getted value to a ref function")
unittest
{
    void fun(ref int x){}
    auto x = some(42);
    fun(x.get);
}