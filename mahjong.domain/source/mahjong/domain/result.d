module mahjong.domain.result;

import mahjong.domain.set;
import mahjong.domain.enums;
import mahjong.domain.tile;
import mahjong.domain.yaku.environment;
import mahjong.util.range;

struct MahjongResult
{
    const bool isMahjong;
    const Set[] sets;
    size_t calculateMiniPoints(const PlayerWinds ownWind, const PlayerWinds leadingWind) pure const
    {
        return sets.sum!(s => s.miniPoints(ownWind, leadingWind));
    }
}

auto tiles(const MahjongResult result) @property pure
{
    return result.sets.flatMap!(s => s.tiles);
}

bool isSevenPairs(const MahjongResult result) pure
{
    return result.sets.length == 1 && cast(SevenPairsSet)result.sets[0];
}

@("A result with a seven pair set is a seven pair mahjong")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new SevenPairsSet(null)]);
    result.isSevenPairs.should.equal(true);
}

@("A thirteen orphan set is not seven pairs")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new ThirteenOrphanSet(null)]);
    result.isSevenPairs.should.equal(false);
}

@("A regular mahjong is not seven pairs")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new PairSet(null), new PonSet(null), new PonSet(null), new PonSet(null), new PonSet(null)]);
    result.isSevenPairs.should.equal(false);
}

bool isThirteenOrphans(const MahjongResult result) pure
{
    return result.sets.length == 1 && cast(ThirteenOrphanSet)result.sets[0];
}

@("A thirteen orphans hand is seen as such")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new ThirteenOrphanSet(null)]);
    result.isThirteenOrphans.should.equal(true);
}

@("Seven pairs is not thirteen orphans")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new SevenPairsSet(null)]);
    result.isThirteenOrphans.should.equal(false);
}

@("A regular mahjong is not thirteen orphans")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new PairSet(null), new PonSet(null), new PonSet(null), new PonSet(null), new PonSet(null)]);
    result.isThirteenOrphans.should.equal(false);
}

bool isNagashiMangan(const MahjongResult result) pure
{
    return result.sets.length == 1 && cast(NagashiManganSet)result.sets[0];
}

@("A result with a seven pair set is a seven pair mahjong")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new NagashiManganSet()]);
    result.isNagashiMangan.should.equal(true);
}

@("A thirteen orphan set is not nagashi mangan")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new ThirteenOrphanSet(null)]);
    result.isNagashiMangan.should.equal(false);
}

@("A regular mahjong is not nagashi mangan")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new PairSet(null), new PonSet(null), new PonSet(null), new PonSet(null), new PonSet(null)]);
    result.isNagashiMangan.should.equal(false);
}

bool hasAtLeastOneChi(const MahjongResult result)
{
    import std.algorithm : any;
    return result.sets.any!(s => s.isChi);
}

@("A mahjong with one or more chis has at least one chi")
unittest
{
    import fluent.asserts;
    auto result1 = MahjongResult(true, [new PairSet(null), new ChiSet(null), new PonSet(null), new PonSet(null), new PonSet(null)]);
    result1.hasAtLeastOneChi.should.equal(true);
    auto result2 = MahjongResult(true, [new PairSet(null), new ChiSet(null), new ChiSet(null), new PonSet(null), new PonSet(null)]);
    result2.hasAtLeastOneChi.should.equal(true);
    auto result3 = MahjongResult(true, [new PairSet(null), new ChiSet(null), new ChiSet(null), new ChiSet(null), new PonSet(null)]);
    result3.hasAtLeastOneChi.should.equal(true);
    auto result4 = MahjongResult(true, [new PairSet(null), new ChiSet(null), new ChiSet(null), new ChiSet(null), new ChiSet(null)]);
    result4.hasAtLeastOneChi.should.equal(true);
}

@("A mahjong with only pons has no chis")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new PairSet(null), new PonSet(null), new PonSet(null), new PonSet(null), new PonSet(null)]);
    result.hasAtLeastOneChi.should.equal(false);
}

bool hasValuelessPair(const MahjongResult result, PlayerWinds leadingWind, PlayerWinds ownWind)
{
    import std.algorithm : filter;
    auto range = result.sets.filter!(s => s.isPair);
    if(range.empty) return false;
    auto pair = range.front;
    return pair.miniPoints(leadingWind, ownWind) == 0;
}

@("A pair of non-honours is a valueless pair")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto result = MahjongResult(true, [new PairSet("🀐🀐"d.convertToTiles)]);
    result.hasValuelessPair(PlayerWinds.east, PlayerWinds.east).should.equal(true);
    auto result2 = MahjongResult(true, [new PairSet("🀖🀖"d.convertToTiles)]);
    result2.hasValuelessPair(PlayerWinds.east, PlayerWinds.east).should.equal(true);
}

@("Dragons and boosted winds are not a valuesless pair")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto result = MahjongResult(true, [new PairSet("🀀🀀"d.convertToTiles)]);
    result.hasValuelessPair(PlayerWinds.south, PlayerWinds.west).should.equal(true);
    auto result2 = MahjongResult(true, [new PairSet("🀁🀁"d.convertToTiles)]);
    result2.hasValuelessPair(PlayerWinds.south, PlayerWinds.west).should.equal(false);
    auto result3 = MahjongResult(true, [new PairSet("🀂🀂"d.convertToTiles)]);
    result3.hasValuelessPair(PlayerWinds.south, PlayerWinds.west).should.equal(false);
    auto result4 = MahjongResult(true, [new PairSet("🀄🀄"d.convertToTiles)]);
    result4.hasValuelessPair(PlayerWinds.east, PlayerWinds.east).should.equal(false);
}

@("A mahjong hand without a pair should not have a valueless pair")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new SevenPairsSet(null)]);
    result.hasValuelessPair(PlayerWinds.east, PlayerWinds.north).should.equal(false);
}

bool hasOnlyChis(const MahjongResult result)
{
    import std.algorithm : all;
    return result.sets.all!(s => s.isChi || s.isPair);
}

@("Is a hand with chis and a pair only chis?")
unittest
{
    import fluent.asserts;
    MahjongResult(true, [new SevenPairsSet(null)]).hasOnlyChis.should.equal(false);
    MahjongResult(true, [new PairSet(null), new ChiSet(null), 
            new PonSet(null), new PonSet(null), new PonSet(null)])
        .hasOnlyChis.should.equal(false);
     MahjongResult(true, [new PairSet(null), new ChiSet(null), 
            new ChiSet(null), new ChiSet(null), new ChiSet(null)])
        .hasOnlyChis.should.equal(true);
}

bool allSetsHaveHonoursOrATerminal(const MahjongResult result)
{
    import std.algorithm : all;
    return result.sets.all!(s => s.tiles.isAllHonour || s.tiles.hasTerminal);
}

@("If the hand only contains terminal sets, is does not count for honours or terminals")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pair = new PairSet("🀇🀇"d.convertToTiles);
    auto chi = new ChiSet("🀟🀠🀡"d.convertToTiles);
    auto pon = new PonSet("🀄🀄🀄"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi, pon]);
    result.allSetsHaveHonoursOrATerminal.should.equal(true);
}

@("If the hand only contains terminal sets, is does still count for honours or terminals")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pair = new PairSet("🀇🀇"d.convertToTiles);
    auto chi = new ChiSet("🀟🀠🀡"d.convertToTiles);
    auto pon = new PonSet("🀏🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi, pon]);
    result.allSetsHaveHonoursOrATerminal.should.equal(true);
}

@("If the hand contains a non terminal set, it is not only honours or terminals")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pair = new PairSet("🀇🀇"d.convertToTiles);
    auto chi = new ChiSet("🀟🀠🀡"d.convertToTiles);
    auto pon = new PonSet("🀠🀠🀠"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi, pon]);
    result.allSetsHaveHonoursOrATerminal.should.equal(false);
}

bool isTwoSidedWait(const MahjongResult result, const Tile lastTile)
{
    import std.algorithm : any, countUntil;
    auto finalSet = result.finalSet(lastTile);
    if(finalSet.isChi)
    {
        auto position = finalSet.tiles.countUntil!(t => t == lastTile);
        bool isClosedWait = position == 1;
        if(isClosedWait) return false;
        bool isLowerEdgeWait = position == 2 && lastTile.value == Numbers.three;
        bool isUpperEdgeWait = position == 0 && lastTile.value == Numbers.seven;
        bool isEdgeWait = isLowerEdgeWait || isUpperEdgeWait;
        return !isEdgeWait;
    }
    return false;
}

@("Finishing on a pair is not a two sided wait")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pair = new PairSet("🀃🀃"d.convertToTiles);
    auto lastTile = pair.tiles[0];
    auto result = MahjongResult(true, [pair]);
    result.isTwoSidedWait(lastTile).should.equal(false);
}

@("Finishing on a pon is not a two sided wait")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pon = new PonSet("🀐🀐🀐"d.convertToTiles);
    auto lastTile = pon.tiles[0];
    auto result = MahjongResult(true, [pon]);
    result.isTwoSidedWait(lastTile).should.equal(false);
}

@("Finishing on the outside of the chi is a two-sided wait")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto chi = new ChiSet("🀒🀓🀔"d.convertToTiles);
    auto lastTile1 = chi.tiles[0];
    auto lastTile2 = chi.tiles[2];
    auto result = MahjongResult(true, [chi]);
    result.isTwoSidedWait(lastTile1).should.equal(true);
    result.isTwoSidedWait(lastTile2).should.equal(true);
}

@("Finishing with a closed wait is not a two-sided wait")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto chi = new ChiSet("🀒🀓🀔"d.convertToTiles);
    auto lastTile = chi.tiles[1];
    auto result = MahjongResult(true, [chi]);
    result.isTwoSidedWait(lastTile).should.equal(false);
}

@("Edge waits are not considered two-sided waits")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto chiLeft = new ChiSet("🀐🀑🀒"d.convertToTiles);
    auto lastTileLeft = chiLeft.tiles[2];
    auto resultLeft = MahjongResult(true, [chiLeft]);
    resultLeft.isTwoSidedWait(lastTileLeft).should.equal(false);

    auto chiRight = new ChiSet("🀖🀗🀘"d.convertToTiles);
    auto lastTileRight = chiRight.tiles[0];
    auto resultRight = MahjongResult(true, [chiRight]);
    resultRight.isTwoSidedWait(lastTileRight).should.equal(false);
}

bool isPonWait(const MahjongResult result, const Tile lastTile)
{
    return result.finalSet(lastTile).isPon;
}

@("If the final tile is in a chi, it is not a pon wait")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto chi= new ChiSet("🀐🀑🀒"d.convertToTiles);
    auto lastTile = chi.tiles[0];
    auto result = MahjongResult(true, [chi]);
    result.isPonWait(lastTile).should.equal(false);
}

@("If the final tile is in a pon, it is a pon wait")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pon= new PonSet("🀄🀄🀄"d.convertToTiles);
    auto lastTile = pon.tiles[0];
    auto result = MahjongResult(true, [pon]);
    result.isPonWait(lastTile).should.equal(true);
}

private const(Set) finalSet(const MahjongResult result, const Tile lastTile)
{
    import std.algorithm : any, filter;
    return result.sets.filter!(s => s.tiles.any!(t => t == lastTile)).front;
}

bool hasOnlyPons(const MahjongResult result)
{
    import std.algorithm : all;
    return result.sets.all!(s => s.isPon || s.isPair);
}

@("A hand of four pons and a pair should have only pons")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new PonSet(null), new PonSet(null), new PonSet(null), new PonSet(null), new PairSet(null)]);
    result.hasOnlyPons.should.equal(true);
}

@("A hand with chis is not only pons")
unittest
{
    import fluent.asserts;
    auto result = MahjongResult(true, [new ChiSet(null), new PonSet(null), new PonSet(null), new PonSet(null), new PairSet(null)]);
    result.hasOnlyPons.should.equal(false);
}

bool allSetsHaveATerminal(const MahjongResult result)
{
    import std.algorithm : all;
    return result.sets.all!(s => s.tiles.hasTerminal);
}

@("Does every set have a terminal")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pair = new PairSet("🀇🀇"d.convertToTiles);
    auto chi = new ChiSet("🀟🀠🀡"d.convertToTiles);
    auto pon = new PonSet("🀏🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi, pon]);
    result.allSetsHaveATerminal.should.equal(true);
}

@("If a set has no terminals, not all sets have a terminal")
unittest
{
    import fluent.asserts;
    import mahjong.domain.creation;
    auto pair = new PairSet("🀁🀁"d.convertToTiles);
    auto chi = new ChiSet("🀟🀠🀡"d.convertToTiles);
    auto pon = new PonSet("🀏🀏🀏"d.convertToTiles);
    auto result = MahjongResult(true, [pair, chi, pon]);
    result.allSetsHaveATerminal.should.equal(false);
}

bool isMahjongWithYaku(const MahjongResult result, const Environment env)
{
    import mahjong.domain.yaku : determineYaku;

    if(!result.isMahjong) return false;
    auto yaku = determineYaku(result, env);
    return yaku.length > 0;
}

@("Thirteen orphans is a mahjong with yaku")
unittest
{
    import fluent.asserts;
    import mahjong.domain.ingame;
    import mahjong.domain.mahjong;

    auto game = new Ingame(PlayerWinds.west, "🀀🀁🀂🀃🀄🀄🀅🀆🀇🀏🀐🀘🀙🀡"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0]
    };
    result.isMahjongWithYaku(env).should.equal(true);
}

@("A hand that is not mahjong has no mahjong with yaku")
unittest
{
    import fluent.asserts;

    auto result = MahjongResult(false, null);
    result.isMahjongWithYaku(Environment.init).should.equal(false);
}

@("A hand without yaku is not a mahjong with yaku")
unittest
{
    import fluent.asserts;
    import mahjong.domain.ingame;
    import mahjong.domain.mahjong;

    auto game = new Ingame(PlayerWinds.west, "🀁🀁🀁🀇🀈🀉🀚🀛🀜🀞🀞🀔🀕🀖"d);
    auto result = scanHandForMahjong(game);
    Environment env = {
            leadingWind: PlayerWinds.east, 
            ownWind: PlayerWinds.west,
            lastTile: game.closedHand.tiles[0]
    };
    game.closedHand.tiles[0].isNotOwn;
    game.closedHand.tiles[0].isDiscarded;
    result.isMahjongWithYaku(env).should.equal(false);
}