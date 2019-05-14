module mahjong.util.traits;

template EnumMembers(E) // Shamelessly copied from std.traits.
if(is(E  == enum))
{
    struct Member
    {
        E value;
        string name;
    }
    import std.meta : AliasSeq;

    template EnumSpecificMembers(names...)
    {
        static if (names.length == 1)
        {
            alias EnumSpecificMembers = AliasSeq!(
                    Member(__traits(getMember, E, names[0]), names[0]));
        }
        else static if (names.length > 0)
        {
            alias EnumSpecificMembers =
                AliasSeq!(
                    Member(__traits(getMember, E, names[0]), names[0]),
                    EnumSpecificMembers!(names[1 .. $/2]),
                    EnumSpecificMembers!(names[$/2..$])
                );
        }
        else
        {
            alias EnumSpecificMembers = AliasSeq!();
        }
    }

    alias EnumMembers = EnumSpecificMembers!(__traits(allMembers, E));
}

@("Can I get the name and value of the enum members?")
unittest
{
    import fluent.asserts;
    enum Foo { bar = 42 }
    EnumMembers!Foo.length.should.equal(1);
    EnumMembers!Foo[0].name.should.equal("bar");
    EnumMembers!Foo[0].value.should.equal(Foo.bar);
}

@("Can I generate an enum with multiple members")
unittest
{
    import std.algorithm : map;
    import fluent.asserts;
    enum Foo { bar, baz}
    enum Direction { x, y, z}
    EnumMembers!Foo.length.should.equal(2);
    EnumMembers!Direction.length.should.equal(3);
    [EnumMembers!Foo].map!(m => m.name).should.containOnly(["bar", "baz"]);
    [EnumMembers!Foo].map!(m => m.value).should.containOnly([Foo.bar, Foo.baz]);
}