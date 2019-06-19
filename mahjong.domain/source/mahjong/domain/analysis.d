module mahjong.domain.analysis;

import optional.optional;
import mahjong.domain.tile;
import mahjong.util.collections;

public import mahjong.util.collections : NoGcArray;

alias Hand = NoGcArray!(14, const Tile);
alias Combi = NoGcArray!(4, const Tile);

Hand asHand(const(Tile)[] tiles) pure @nogc nothrow
{
    return tiles.array!14;
}

bool isSeperated(ref const Optional!Combi set) @property pure @nogc nothrow
{
    return set != none;
}

@("A hand set seperation means they are seperated")
unittest
{
    import fluent.asserts;
    auto set = some(Combi());
    isSeperated(set).should.equal(true);
}

@("No hand set seperation means the hand is not seperated")
unittest
{
    import fluent.asserts;
    auto set = no!Combi;
    isSeperated(set).should.equal(false);
}

Optional!Combi seperateChi(ref Hand hand) pure @nogc nothrow
{
    if(hand[0].isHonour) return no!Combi;
    Combi chi;
    chi ~= hand[0];
    immutable type = chi[0].type;
    foreach (tile; hand)
	{
        if(tile.type != type) return no!Combi;
		if (tile.value == chi[$ - 1].value + 1)
		{
			chi ~= tile;
			if (chi.length == 3)
			{
                hand.remove(chi);
				return some(chi);
			}
		}
	}
    return no!Combi;
}

@("If I have a chi at the start of my hand, it gets seperated")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀈🀉🀊🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto set = seperateChi(hand);
    set.isSeperated.should.equal(true);
    hand.length.should.equal(2);
    set.unwrap.length.should.equal(3);
    hand.should.containOnly(tiles[3 .. $]);
    set.unwrap.should.containOnly(tiles[0 .. 3]);
}

@("If I have duplicates in my chi, I can still destill it")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀈🀈🀉🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto set = seperateChi(hand);
    set.isSeperated.should.equal(true);
    hand.length.should.equal(2);
    set.unwrap.length.should.equal(3);
    set.unwrap.should.containOnly([tiles[0], tiles[1], tiles[3]]);
    hand.should.containOnly([tiles[2], tiles[4]]);
}

@("If I can't make a chi using the first tile, the seperation fails")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀉🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperateChi(hand);
    seperation.isSeperated.should.equal(false);
    hand.should.equal(tiles.asHand);
}

@("For different types a chi cannot be resolved")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀑🀒"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperateChi(hand);
    seperation.isSeperated.should.equal(false);
}

@("Honours cannot be resolved into a chi")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀀🀁🀂"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperateChi(hand);
    seperation.isSeperated.should.equal(false);
}

@("The seperation is denied gracefully if I don't have enough tiles for a chi")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀀"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperateChi(hand);
    seperation.isSeperated.should.equal(false);
}

@("Searching for a chi should be efficient.")
unittest
{
    import core.time;
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀈🀉🀊🀊🀐🀑🀒🀙🀚🀛🀠🀠🀠"d.convertToTiles;
    ({auto hand = tiles.asHand;
    seperateChi(hand);}).should.haveExecutionTime.lessThan(5.usecs);
}

alias seperatePon = seperateSetWithSameValueOfGivenLength!3;
alias seperatePair = seperateSetWithSameValueOfGivenLength!2;

Optional!Combi seperateSetWithSameValueOfGivenLength(size_t length)(ref Hand hand) 
    pure @nogc nothrow
{
    if(hand.length < length) return no!Combi;
    Combi set;
    set ~= hand[0];
    static foreach(i; 1 .. length)
    {
        if(!set[0].hasEqualValue(hand[i])) return no!Combi;
        set ~= hand[i];
    }
    hand.remove(set);
    return some(set);
}

@("If I start my hand with a pon, it gets seperated")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀇🀇🀊🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto set = seperatePon(hand);
    set.isSeperated.should.equal(true);
    hand.length.should.equal(2);
    set.unwrap.length.should.equal(3);
    hand.should.containOnly(tiles[3 .. $]);
    set.unwrap.should.containOnly(tiles[0 .. 3]);
}

@("If I don't have a pon, it doesn't get seperated")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀇🀊🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto set = seperatePon(hand);
    hand.should.equal(tiles.asHand);
    set.isSeperated.should.equal(false);
}

@("If I am looking for a pon with too little tiles, I get a graceful disappointment")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇"d.convertToTiles;
    auto hand = tiles.asHand;
    auto set = seperatePon(hand);
    set.isSeperated.should.equal(false);
}

@("Searching for a pon should be efficient.")
unittest
{
    import core.time;
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d.convertToTiles;
    ({auto hand = tiles.asHand;
    seperatePon(hand);}).should.haveExecutionTime.lessThan(5.usecs);
}

@("Can I search for a pair")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀇🀊🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto set = seperatePair(hand);
    set.isSeperated.should.equal(true);
    set.unwrap.should.containOnly(tiles[0 .. 2]);
}