module mahjong.domain.analysis;

import optional.optional;
import mahjong.domain.tile;
import mahjong.util.collections;

struct HandSetSeperation
{
    Hand hand;
    Set set;
}

alias Hand = NoGcArray!(14, const Tile);
alias Set = NoGcArray!(3, const Tile);

Hand asHand(const(Tile)[] tiles) pure @nogc nothrow
{
    return tiles.array!14;
}

bool isSeperated(ref const Optional!HandSetSeperation hss) @property pure @nogc nothrow
{
    return hss != none;
}

@("A hand set seperation means they are seperated")
unittest
{
    import fluent.asserts;
    auto hss = some(HandSetSeperation());
    isSeperated(hss).should.equal(true);
}

@("No hand set seperation means the hand is not seperated")
unittest
{
    import fluent.asserts;
    auto hss = no!HandSetSeperation;
    isSeperated(hss).should.equal(false);
}

Optional!HandSetSeperation seperateChi(Hand hand) @property pure @nogc nothrow
{
    if(hand[0].isHonour) return no!HandSetSeperation;
    Set chi;
    chi ~= hand[0];
    immutable type = chi[0].type;
    foreach (tile; hand)
	{
        if(tile.type != type) return no!HandSetSeperation;
		if (tile.value == chi[$ - 1].value + 1)
		{
			chi ~= tile;
			if (chi.length == 3)
			{
                hand.remove(chi);
				return some(HandSetSeperation(hand, chi));
			}
		}
	}
    return no!HandSetSeperation;
}

@("If I have a chi at the start of my hand, it gets seperated")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀈🀉🀊🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperateChi(hand);
    seperation.isSeperated.should.equal(true);
    seperation.unwrap.hand.length.should.equal(2);
    seperation.unwrap.set.length.should.equal(3);
    seperation.unwrap.hand.should.containOnly(tiles[3 .. $]);
    seperation.unwrap.set.should.containOnly(tiles[0 .. 3]);
}

@("If I have duplicates in my chi, I can still destill it")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀈🀈🀉🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperateChi(hand);
    seperation.isSeperated.should.equal(true);
    seperation.unwrap.hand.length.should.equal(2);
    seperation.unwrap.set.length.should.equal(3);
    seperation.unwrap.set.should.containOnly([tiles[0], tiles[1], tiles[3]]);
    seperation.unwrap.hand.should.containOnly([tiles[2], tiles[4]]);
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

Optional!HandSetSeperation seperateSetWithSameValueOfGivenLength(size_t length)(Hand hand) 
    @property pure @nogc nothrow
{
    if(hand.length < length) return no!HandSetSeperation;
    Set set;
    set ~= hand[0];
    static foreach(i; 1 .. 3)
    {
        if(!set[0].hasEqualValue(hand[i])) return no!HandSetSeperation;
        set ~= hand[i];
    }
    hand.remove(set);
    return some(HandSetSeperation(hand, set));
}

@("If I start my hand with a pon, it gets seperated")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀇🀇🀊🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperatePon(hand);
    seperation.isSeperated.should.equal(true);
    seperation.unwrap.hand.length.should.equal(2);
    seperation.unwrap.set.length.should.equal(3);
    seperation.unwrap.hand.should.containOnly(tiles[3 .. $]);
    seperation.unwrap.set.should.containOnly(tiles[0 .. 3]);
}

@("If I don't have a pon, it doesn't get seperated")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇🀇🀊🀊"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperatePon(hand);
    seperation.isSeperated.should.equal(false);
}

@("If I am looking for a pon with too little tiles, I get a graceful disappointment")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    const(Tile)[] tiles = "🀇"d.convertToTiles;
    auto hand = tiles.asHand;
    auto seperation = seperatePon(hand);
    seperation.isSeperated.should.equal(false);
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