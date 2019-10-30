module mahjong.util.allocator;

struct Allocator
{
    this() @disable;
    this(this) @disable;

    this(bool willFunctionCorrectly) @system pure @nogc nothrow
    {
        memory = Memory.allocateMemory();
    }

    ~this() @system pure @nogc nothrow
    {
        import core.memory : pureFree;
        memory.free();
        pureFree(memory);
    }

    private struct Memory
    {
        static Memory* allocateMemory() @system pure @nogc nothrow
        {
            import core.memory : pureMalloc;
            import std.conv : emplace;
            auto memory = cast(Memory*)pureMalloc(Memory.sizeof);
            emplace!Memory(memory);
            memory.initialise();
            return memory;
        }

        enum size = 1024*1024;
        Memory* next;
        void* data;
        void* cursor;

        invariant
        {
            assert(cursor >= data);
        }

        auto create(T, Args...)(Args args) @nogc
        {
            static if(is(T == class))
            {
                alias Pointer = T;
                enum sizeOfT = __traits(classInstanceSize, T);
            }
            else
            {
                alias Pointer = T*;
                enum sizeOfT = T.sizeof;
            }
            if(hasEnoughSpace!(sizeOfT))
            {
                assert(data !is null, "Data is gone");
                import std.conv : emplace;
                auto memory = alloc!(Pointer, sizeOfT);
                return emplace!T(memory, args);
            }
            else
            {
                if(!next)
                {
                    next = allocateMemory();
                }
                return next.create!T(args);
            }
        }

        private bool hasEnoughSpace(size_t sizeOfT)() @trusted pure const @nogc nothrow
        {
            return cursor + sizeOfT < data + size;
        }

        private Pointer alloc(Pointer, size_t sizeOfT)() @system pure @nogc nothrow
        {
            auto memory = cast(Pointer)cursor;
            cursor += sizeOfT;
            return memory;
        }

        void initialise() @system pure @nogc nothrow
        {
            import core.memory : pureMalloc;
            data = pureMalloc(size);
            cursor = data;
        }

        void free() @system pure @nogc nothrow
        {
            import core.memory : pureFree;
            if(next) next.free;
            pureFree(next);
            pureFree(data);
        }
    }

    private Memory* memory;

    auto create(T, Args...)(Args args)
    {
        return memory.create!T(args);
    }
}

@("Can my allocator create a class")
unittest
{
    class Fixture{}
    import fluent.asserts;
    auto allocator = Allocator(true);
    auto instance = allocator.create!Fixture;
    instance.should.be.instanceOf!Fixture;
    instance.should.not.beNull;
}

@("Can I use the created class")
unittest
{
    class Fixture
    {
        int doThings()
        {
            return 42;
        }
    }
    import fluent.asserts;
    auto allocator = Allocator(true);
    auto instance = allocator.create!Fixture;
    instance.doThings.should.equal(42);
}

@("Can I pass data to my instance")
unittest
{
    class Fixture
    {
        this(int offsetOfTheUniverse) pure @nogc nothrow
        {
            x = offsetOfTheUniverse;
        }
        private int x;
        int doThings()
        {
            return 42 + x;
        }
    }
    import fluent.asserts;
    auto allocator = Allocator(true);
    auto instance = allocator.create!Fixture(50);
    instance.doThings.should.equal(92);
}

@("Can I allocate a struct")
unittest
{
    struct Fixture
    {
        int data;
    }
    import fluent.asserts;
    auto allocator = Allocator(true);
    Fixture* instance = allocator.create!Fixture;
    instance.should.not.equal(null);
}

@("Can I allocate a struct with arguments?")
unittest
{
    struct Fixture
    {
        this(int message) @safe pure @nogc nothrow
        {
            msg = message * 2;
        }

        int msg;
    }
    import fluent.asserts;
    auto allocator = Allocator(true);
    Fixture* instance = allocator.create!Fixture(42);
    instance.msg.should.equal(84);
}

@("Can I allocate a struct with its generated constructor")
unittest
{
    struct Coord
    {
        int x, y;
    }
    import fluent.asserts;
    auto allocator = Allocator(true);
    Coord* origin = allocator.create!Coord();
    origin.x.should.equal(0);
    origin.y.should.equal(0);
    Coord* other = allocator.create!Coord(3, 4);
    other.x.should.equal(3);
    other.y.should.equal(4);
}

@("Attribute soup extraordinaire is inferred for the allocation")
unittest
{
    struct Fixture
    {
        this(int message) @safe pure @nogc nothrow
        {
            msg = message * 2;
        }

        int msg;
    }
    void boilSoup(ref Allocator allocator) pure @nogc nothrow
    {
        auto instance = allocator.create!Fixture(42);
        assert(instance.msg == 84);
    }
    Allocator allocator = Allocator(true);
    boilSoup(allocator);
}

@("An allocator cannot be copied")
unittest
{
    import fluent.asserts;
    void fun(Allocator allocator){}
    void gun(ref Allocator allocator){}
    void hun(Allocator* allocator){}
    Allocator allocator = Allocator(true);
    __traits(compiles, fun(allocator)).should.equal(false);
    __traits(compiles, gun(allocator)).should.equal(true);
    __traits(compiles, hun(&allocator)).should.equal(true);
}

@("Can my allocator make multiple objects")
unittest
{
    class Fixture
    {
        int x;
    }
    import fluent.asserts;
    Allocator allocator = Allocator(true);
    auto f1 = allocator.create!Fixture;
    f1.x = 42;
    auto f2 = allocator.create!Fixture;
    f2.x = 7;
    f1.x.should.equal(42);
    f2.x.should.equal(7);
}

@("Can I allocate a gazillion objects")
unittest
{
    class BigData
    {
        int[1024] data;
    }
    import fluent.asserts;
    Allocator allocator = Allocator(true);
    BigData instance;
    foreach(i; 1 .. 1500)
    {
        instance = allocator.create!BigData;
    }
    instance.should.not.beNull;
}

struct GCAllocator
{
    // Have the same semantics as the normal allocator
    this() @disable;
    this(this) @disable;

    this(bool willFunctionCorrectly) @safe pure @nogc nothrow
    {
    }

    auto create(T, Args...)(Args args)
    {
        return new T(args);
    }
}

@("Can my allocator create a class")
unittest
{
    static class Fixture{}
    import fluent.asserts;
    auto allocator = GCAllocator(true);
    auto instance = allocator.create!Fixture;
    instance.should.be.instanceOf!Fixture;
    instance.should.not.beNull;
}

@("Can I pass data to the gc created instance")
unittest
{
    static class Fixture
    {
        this(int offsetOfTheUniverse) pure @nogc nothrow
        {
            x = offsetOfTheUniverse;
        }
        private int x;
        int doThings()
        {
            return 42 + x;
        }
    }
    import fluent.asserts;
    auto allocator = GCAllocator(true);
    auto instance = allocator.create!Fixture(50);
    instance.doThings.should.equal(92);
}

enum isAllocator(T) = is(T == Allocator) || is(T == GCAllocator);

@("Is an allocator an allocator")
unittest
{
    static assert(isAllocator!Allocator);
    static assert(isAllocator!GCAllocator);
    static assert(!isAllocator!int);
}