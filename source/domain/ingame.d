module mahjong.domain.ingame;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.traits;
import std.uuid;
import mahjong.domain;
import mahjong.domain.enums;
import mahjong.domain.exceptions;
import mahjong.engine.chi;
import mahjong.engine.mahjong;
import mahjong.engine.sort;
import mahjong.share.range;

class Ingame
{ 
    this(PlayerWinds wind)
    {
        this.wind = wind;
        closedHand = new ClosedHand;
        openHand = new OpenHand;
        id = randomUUID;
    }

    const UUID id;
    // Ingame variables.
    const PlayerWinds wind; // What wind the player has. Initialise it with a value of -1 to allow easy assert(ingame.wind >= 0).

    bool isEast() @property pure const
    {
        return wind == PlayerWinds.east;
    }

    ClosedHand closedHand; // The closed hand that can be changed. The discards are from here.
    OpenHand openHand; // The open pons/chis/kans 

    private Tile[] _discards;
    const(Tile)[] discards() @property pure const
    {
        return _discards;
    }

    version(unittest)
    {
        void setDiscards(Tile[] discs)
        {
            _discards = discs;
            foreach(tile; _discards)
            {
                tile.origin = this;
            }
        }
    }

    private Tile[] _claimedDiscards;
    private const(Tile)[] allDiscards() @property pure
    {
        return discards ~_claimedDiscards;
    }

    void discardIsClaimed(Tile tile)
    {
        _discards.remove!((a, b) => a == b)(tile);
        _claimedDiscards ~= tile;
    }

    bool isNagashiMangan() @property
    {
        return openHand.sets.empty && allDiscards.all!(t => t.isHonour || t.isTerminal);
    }

    bool isClosedHand() @property pure const
    {
        return openHand.isClosedHand;
    }

    /*
     Normal functions related to claiming tiles.
     */
    private bool isOwn(const Tile tile) pure const
    {
        return tile.origin is null;
    }

    bool isChiable(const Tile discard) pure const
    {
        if(isOwn(discard)) return false;
        return closedHand.isChiable(discard);
    }

    void chi(Tile discard, ChiCandidate otherTiles)
    {
        if(!isChiable(discard) || !otherTiles.isChi(discard)) 
        {
            throw new IllegalClaimException(discard, "Chi not allowed");
        }
        discard.claim;
        auto chiTiles = closedHand.removeChiTiles(otherTiles) ~ discard;
        openHand.addChi(chiTiles);
        _lastTile = discard;
        startTurn;
    }

    bool isPonnable(const Tile discard) pure
    {
        if(isOwn(discard)) return false;
        return closedHand.isPonnable(discard);
    }

    void pon(Tile discard)
    {
        if(!isPonnable(discard)) throw new IllegalClaimException(discard, "Pon not allowed");
        discard.claim;
        auto ponTiles = closedHand.removePonTiles(discard) ~ discard;
        openHand.addPon(ponTiles);
        _lastTile = discard;
        startTurn;
    }

    bool isKannable(const Tile discard) pure
    {
        if(isOwn(discard)) return false;
        return closedHand.isKannable(discard);
    }

    void kan(Tile discard, Wall wall)
    {
        if(!isKannable(discard)) throw new IllegalClaimException(discard, "Kan not allowed");
        discard.claim;
        auto kanTiles = closedHand.removeKanTiles(discard) ~ discard;
        openHand.addKan(kanTiles);
        drawKanTile(wall);
        startTurn;
    }

    bool isRonnable(const Tile discard) pure
    {
        return scanHandForMahjong(this, discard).isMahjong
            && !isFuriten ;
    }

    void ron(Tile discard)
    {
        if(!isRonnable(discard)) 
        {
            throw new IllegalClaimException(discard, "The tile could not have been ronned.");
        }
        _lastTile = discard;
        closedHand.tiles ~= discard;
    }

    void couldHaveClaimed(const Tile tile)
    {
        if(tile.origin is this) return;
        _isTemporaryFuriten = _isTemporaryFuriten 
            || .scanHandForMahjong(this, tile).isMahjong;
    }
    
    bool canDeclareClosedKan(const Tile tile) pure const
    {
        return closedHand.canDeclareClosedKan(tile);
    }

    void declareClosedKan(const Tile tile, Wall wall)
    {
        auto kanTiles = closedHand.declareClosedKan(tile);
        openHand.addKan(kanTiles);
        drawKanTile(wall);
    }

    bool canPromoteToKan(const Tile tile) pure const
    {
        return openHand.canPromoteToKan(tile);
    }

    void promoteToKan(const Tile selectedTile, Wall wall)
    {
        auto tile = closedHand.removeTile(selectedTile);
        openHand.promoteToKan(tile);
        drawKanTile(wall);
    }

    private void drawKanTile(Wall wall)
    {
        closedHand.drawKanTile(wall);
        _lastTile = closedHand.lastTile;
    }

    /*
     Functions related to the mahjong call.
     */

    bool isTenpai()
    {
        foreach(type; EnumMembers!Types)
        {
            for(int value = Numbers.min; value <= Numbers.max; ++value)
            {
                auto tile = new Tile(type, value);
                if(.scanHandForMahjong(this, tile).isMahjong)
                {
                    return true;
                }

            }
        }
        return false;
    }

    bool isFuriten() @property pure
    {
        if(_isTemporaryFuriten) return true;
        foreach(tile; allDiscards)
        {
            if(.scanHandForMahjong(this, tile).isMahjong)
            {
                return true;
            }
        }
        return false;
    }
    private bool _isTemporaryFuriten;

    bool canTsumo() pure const
    {
        return  isOwn(_lastTile) && isMahjong;
    }

    bool isMahjong() pure const
    {
        return scanHandForMahjong(this).isMahjong;
    }

    Tile discard(const Tile discardedTile)
    {
        auto tile = closedHand.removeTile(discardedTile);
        _discards ~= tile;
        tile.origin = this;
        tile.open;
        return tile;
    }

    private Tile _lastTile; 
    const(Tile) lastTile() @property pure const
    {
        return _lastTile;
    }

    void closeHand()
    {
        closedHand.closeHand;
    }

    void showHand()
    {
        closedHand.showHand;
    }
    
    void drawTile(Wall wall)
    {
        closedHand.drawTile(wall);
        _lastTile = closedHand.lastTile;
        startTurn;
    }

    private void startTurn()
    {
        _isTemporaryFuriten = false;
    }
}

unittest
{
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
    auto tile = ingame.closedHand.tiles.back;
    auto initialLength = ingame.closedHand.tiles.length;
    auto wall = new Wall;
    wall.setUp;
    wall.dice;
    ingame.declareClosedKan(tile, wall);
    assert(ingame.closedHand.tiles.length == initialLength - 3, "Four tiles should have been subtracted from the hand and one added");
    assert(ingame.openHand.amountOfKans == 1, "The open hand should have a kan");
}
unittest
{
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
    auto tile = ingame.closedHand.tiles.back;
    tile.origin = new Ingame(PlayerWinds.south);
    ingame.pon(tile);
    auto initialLength = ingame.closedHand.tiles.length;
    auto wall = new Wall;
    wall.setUp;
    wall.dice;
    ingame.promoteToKan(ingame.closedHand.tiles.back, wall);
    assert(ingame.closedHand.tiles.length == initialLength, "One tile should have been subtracted from the hand and one added");
    assert(ingame.openHand.amountOfKans == 1, "The open hand should have a kan");
}
unittest
{
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto ponTile = "🀟"d.convertToTiles[0];
    ponTile.origin = new Ingame(PlayerWinds.south);
    ingame.pon(ponTile);
    assert(!ingame.canTsumo, "After a claiming a tile, the player should no longer be able to tsumo.");
}
unittest
{
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto chiTile = "🀡"d.convertToTiles[0];
    chiTile.origin = new Ingame(PlayerWinds.south);
    ingame.chi(chiTile, ChiCandidate(ingame.closedHand.tiles[6], ingame.closedHand.tiles[8]));
    assert(!ingame.canTsumo, "After a claiming a tile, the player should no longer be able to tsumo.");
}

unittest
{
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto ronTile = "🀡"d.convertToTiles[0];
    ronTile.origin = new Ingame(PlayerWinds.south);
    ingame.ron(ronTile);
    assert(ingame.isMahjong, "After ronning, the player should have mahjong");
    assert(ingame.lastTile == ronTile, "The player should confess they claimed the last tile");
}

unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto ronTile = "🀡"d.convertToTiles[0];
    ingame.couldHaveClaimed(ronTile);
    ingame.isFuriten.should.equal(true);
}
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto randomTile = "🀀"d.convertToTiles[0];
    ingame.couldHaveClaimed(randomTile);
    ingame.isFuriten.should.equal(false);
}
unittest
{
    import fluent.asserts;
    import mahjong.engine.creation;
    import mahjong.engine.opts;
    gameOpts = new DefaultGameOpts;
    auto ingame = new Ingame(PlayerWinds.east);
    ingame.closedHand.tiles = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
    auto ronTile = "🀡"d.convertToTiles[0];
    ingame.couldHaveClaimed(ronTile);
    ingame.isFuriten.should.equal(true);
    auto randomTile = "🀀"d.convertToTiles[0];
    ingame.couldHaveClaimed(randomTile);
    ingame.isFuriten.should.equal(true);
}