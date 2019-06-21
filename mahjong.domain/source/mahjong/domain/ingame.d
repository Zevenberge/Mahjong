module mahjong.domain.ingame;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.uuid;
import mahjong.domain;
import mahjong.domain.chi;
import mahjong.domain.enums;
import mahjong.domain.exceptions;
import mahjong.domain.mahjong;
import mahjong.domain.yaku.environment;
import mahjong.util.range;

class Ingame
{
    this(PlayerWinds wind)
    {
        this.wind = wind;
        closedHand = new ClosedHand;
        openHand = new OpenHand;
        id = randomUUID;
    }

    version (mahjong_test)
    {
        this(PlayerWinds wind, dstring tiles)
        {
            import mahjong.domain.creation;

            this(wind);
            closedHand.tiles = tiles.convertToTiles;
            closedHand.tiles.each!(t => t.isDrawnBy(this));
        }

        void setDiscards(Tile[] discs)
        {
            _discards = discs;
            foreach (tile; _discards)
            {
                tile.isDrawnBy(this);
                tile.isDiscarded;
            }
        }

        void hasDrawnTheirLastTile() pure
        {
            _lastTile = closedHand.tiles[0];
            _lastTile.isDrawnBy(this);
        }

        void isNotNagashiMangan()
        {
            _discards ~= new Tile(Types.ball, Numbers.five);
        }

        void willBeTenpai()
        {
            import mahjong.domain.creation;

            closedHand.tiles
                = "🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
        }

        void willNotBeTenpai()
        {
            import mahjong.domain.creation;

            closedHand.tiles
                = "🀇🀇🀇🀈🀈🀈🀈🀌🀌🀊🀊🀆🀆"d.convertToTiles;
        }
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
    const(Tile)[] discards() @property pure const @nogc nothrow
    {
        return _discards;
    }

    private Tile[] _claimedDiscards;
    private auto allDiscards() @property pure const @nogc nothrow
    {
        import std.range : chain;
        return discards.chain(_claimedDiscards);
    }

    void discardIsClaimed(Tile tile)
    {
        _discards.remove!((a, b) => a == b)(tile);
        _claimedDiscards ~= tile;
    }

    void aTileHasBeenClaimed() pure @nogc nothrow
    {
        _isFirstTurnAfterRiichi = false;
    }

    @("When someone claims a tile, it is no longer the first turn after riichi")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.declareRiichi(toBeDiscardedTile, false);
        ingame.aTileHasBeenClaimed;
        ingame.isFirstTurnAfterRiichi.should.equal(false);
    }

    bool isNagashiMangan() @property pure const @nogc nothrow
    {
        return openHand.isClosedHand && allDiscards.all!(t => t.isHonour || t.isTerminal);
    }

    @("When starting, the player is nagashi mangan")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.isNagashiMangan.should.equal(true);
    }

    @("When discarding a honour, the player remains nagashi mangan")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
        ingame.discard(ingame.closedHand.tiles[0]);
        ingame.isNagashiMangan.should.equal(true);
    }

    @("When discarding a terminal, the player remains nagashi mangan")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
        ingame.discard(ingame.closedHand.tiles[11]);
        ingame.isNagashiMangan.should.equal(true);
    }

    @("When discarding a normal tile, the player loses nagashi mangan")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀟"d);
        ingame.discard(ingame.closedHand.tiles[11]);
        ingame.isNagashiMangan.should.equal(false);
    }

    @("When claiming a tile, the player loses nagashi mangan")
    unittest
    {
        import fluent.asserts;
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀟"d);
        auto tile = new Tile(Types.wind, Winds.east);
        tile.isNotOwn;
        ingame.pon(tile);
        ingame.isNagashiMangan.should.equal(false);
    }

    bool isClosedHand() @property pure const @nogc nothrow
    {
        return openHand.isClosedHand;
    }

    /*
     Normal functions related to claiming tiles.
     */
    private bool canClaim(const Tile tile) pure const
    {
        return !isOwn(tile) && !_isRiichi;
    }

    private bool isOwn(const Tile tile) pure const
    {
        return tile.isOwnedBy(this);
    }

    bool isChiable(const Tile discard) pure const
    {
        if (!canClaim(discard))
            return false;
        return closedHand.isChiable(discard);
    }

    @("Can I chi a tile")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;

        auto game = new Ingame(PlayerWinds.east);
        game.closedHand.tiles = "🀓🀔"d.convertToTiles;
        auto chiableTile = "🀕"d.convertToTiles[0];
        chiableTile.isNotOwn;
        game.isChiable(chiableTile).should.equal(true);
        game.closedHand.tiles = "🀓🀕"d.convertToTiles;
        chiableTile = "🀔"d.convertToTiles[0];
        chiableTile.isNotOwn;
        game.isChiable(chiableTile).should.equal(true);
        game.closedHand.tiles = "🀔🀕"d.convertToTiles;
        chiableTile = "🀓"d.convertToTiles[0];
        chiableTile.isNotOwn;
        game.isChiable(chiableTile).should.equal(true);
        game.closedHand.tiles = "🀓🀔"d.convertToTiles;
        auto nonChiableTile = "🀔"d.convertToTiles[0];
        nonChiableTile.isNotOwn;
        game.isChiable(nonChiableTile).should.equal(false);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;

        auto game = new Ingame(PlayerWinds.east, "🀀🀁"d);
        auto nonChiableTile = "🀂"d.convertToTiles[0];
        nonChiableTile.isNotOwn;
        game.isChiable(nonChiableTile).should.equal(false);
        game = new Ingame(PlayerWinds.east, "🀄🀅"d);
        nonChiableTile = "🀆"d.convertToTiles[0];
        nonChiableTile.isNotOwn;
        game.isChiable(nonChiableTile).should.equal(false);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        ingame.declareRiichi(ingame.closedHand.tiles.front,
                new Metagame([new Player(30_000)], new DefaultGameOpts));
        auto tile = "🀡"d.convertToTiles[0];
        tile.isNotOwn;
        ingame.isChiable(tile).should.equal(false);
    }

    void chi(Tile discard, ChiCandidate otherTiles)
    {
        if (!isChiable(discard) || !otherTiles.isChi(discard))
        {
            throw new IllegalClaimException(discard, "Chi not allowed");
        }
        discard.claim;
        auto chiTiles = closedHand.removeChiTiles(otherTiles) ~ discard;
        openHand.addChi(chiTiles);
        _lastTile = discard;
        startTurn;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.exceptions;
        import mahjong.domain.creation;

        auto game = new Ingame(PlayerWinds.east, "🀓🀔"d);
        auto tiles = game.closedHand.tiles;
        auto candidate = ChiCandidate(tiles[0], tiles[1]);
        auto chiableTile = "🀕"d.convertToTiles[0];
        chiableTile.isNotOwn;
        game.chi(chiableTile, candidate);
        game.closedHand.length.should.equal(0)
            .because("the tiles should have been removed from the hand");
        game.openHand.amountOfChis.should.equal(1);
        game.openHand.sets.length.should.equal(1);
        (() => game.chi(chiableTile, candidate)).should.throwException!IllegalClaimException;
    }

    bool isPonnable(const Tile discard) pure const
    {
        if (!canClaim(discard))
            return false;
        return closedHand.isPonnable(discard);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;

        auto game = new Ingame(PlayerWinds.east);
        game.closedHand.tiles = "🀕🀕"d.convertToTiles;
        auto ponnableTile = "🀕"d.convertToTiles[0];
        ponnableTile.isNotOwn;
        game.isPonnable(ponnableTile).should.equal(true);
        auto nonPonnableTile = "🀃"d.convertToTiles[0];
        game.isPonnable(nonPonnableTile).should.equal(false);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        ingame.declareRiichi(ingame.closedHand.tiles.front,
                new Metagame([new Player(30_000)], new DefaultGameOpts));
        auto tile = "🀡"d.convertToTiles[0];
        tile.isNotOwn;
        ingame.isPonnable(tile).should.equal(false);
    }

    void pon(Tile discard)
    {
        if (!isPonnable(discard))
            throw new IllegalClaimException(discard, "Pon not allowed");
        discard.claim;
        auto ponTiles = closedHand.removePonTiles(discard) ~ discard;
        openHand.addPon(ponTiles);
        _lastTile = discard;
        startTurn;
    }

    @("Can I declare a pon")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.exceptions;

        auto game = new Ingame(PlayerWinds.east, "🀕🀕"d);
        auto ponnableTile = "🀕"d.convertToTiles[0];
        ponnableTile.isNotOwn;
        game.pon(ponnableTile);
        game.closedHand.length.should.equal(0)
            .because("the tiles should have been removed from the hand");
        game.openHand.amountOfPons.should.equal(1);
        game.openHand.sets.length.should.equal(1);
        (() => game.pon(ponnableTile)).should.throwException!IllegalClaimException;
    }

    bool isKannable(const Tile discard, const Wall wall) const
    {
        if (!canClaim(discard) || wall.isMaxAmountOfKansReached)
            return false;
        return closedHand.isKannable(discard);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        class MaybeKanWall : Wall
        {
            this(bool isMaxAmountOfKansReached)
            {
                super(new DefaultGameOpts);
                _isMaxAmountOfKansReached = isMaxAmountOfKansReached;
            }

            private const bool _isMaxAmountOfKansReached;
            override bool isMaxAmountOfKansReached() const
            {
                return _isMaxAmountOfKansReached;
            }
        }

        auto ingame = new Ingame(PlayerWinds.east);
        auto tile = new Tile(Types.ball, Numbers.eight);
        tile.isNotOwn;
        ingame.closedHand.tiles = [tile, tile, tile];
        auto wall = new MaybeKanWall(false);
        ingame.isKannable(tile, wall).should.equal(true)
            .because("the wall still has kan tiles left");
        wall = new MaybeKanWall(true);
        ingame.isKannable(tile, wall).should.equal(false)
            .because("the wall has no more kan tiles left");
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        ingame.declareRiichi(ingame.closedHand.tiles.front,
                new Metagame([new Player(30_000)], new DefaultGameOpts));
        auto tile = "🀡"d.convertToTiles[0];
        tile.isNotOwn;
        ingame.isKannable(tile, new Wall(new DefaultGameOpts)).should.equal(false);
    }

    void kan(Tile discard, Wall wall)
    {
        if (!isKannable(discard, wall))
            throw new IllegalClaimException(discard, "Kan not allowed");
        discard.claim;
        auto kanTiles = closedHand.removeKanTiles(discard) ~ discard;
        openHand.addKan(kanTiles);
        drawKanTile(wall);
        startTurn;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.exceptions;
        import mahjong.domain.opts;

        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        auto game = new Ingame(PlayerWinds.east, "🀕🀕🀕"d);
        auto kannableTile = "🀕"d.convertToTiles[0];
        kannableTile.isNotOwn;
        game.kan(kannableTile, wall);
        game.closedHand.length.should.equal(1)
            .because("all of the tiles should have been moved and a new one drawn");
        game.openHand.amountOfPons.should.equal(1).because("the kan counts as a pon");
        game.openHand.amountOfKans.should.equal(1);
        game.openHand.sets.length.should.equal(1);
        (() => game.kan(kannableTile, wall)).should.throwException!IllegalClaimException;
    }

    bool isRonnable(const Tile discard, const Metagame metagame) const
    {
        auto environment = destillEnvironmentForPotentialRon(this, discard,
                metagame.leadingWind, metagame.isFirstTurn, metagame.isExhaustiveDraw);
        return isLegitMahjongClaim(discard, environment);        
    }

    @("Can a player ron a tile if they have a yaku")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto game = new Ingame(PlayerWinds.east,
                "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d);
        auto ronTile = "🀐"d.convertToTiles[0];
        ronTile.isNotOwn;
        ronTile.isDiscarded;
        game.isRonnable(ronTile, metagame).should.equal(true);
    }

    @("Can a player not ron if they are furiten")
    unittest
    {
        void addTileToDiscard(Ingame game, Tile tile)
        {
            game.closedHand.tiles ~= tile;
            game.discard(tile);
        }

        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto game = new Ingame(PlayerWinds.east,
                "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d);
        auto ronTile = "🀐"d.convertToTiles[0];
        ronTile.isNotOwn;
        ronTile.isDiscarded;
        addTileToDiscard(game, "🀐"d.convertToTiles[0]);
        game.isRonnable(ronTile, metagame).should.equal(false)
            .because("the player is furiten on the same tile");
        game = new Ingame(PlayerWinds.east, "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d);
        addTileToDiscard(game, "🀖"d.convertToTiles[0]);
        game.isRonnable(ronTile, metagame).should.equal(false)
            .because("the player is furiten on another out");
    }

    @("Can a player not ron if they have no yaku")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto game = new Ingame(PlayerWinds.east,
                "🀐🀐🀑🀒🀓🀔🀕🀇🀇🀜🀝🀞"d);
        auto ponTile = new Tile(Types.character, Numbers.one);
        ponTile.isNotOwn;
        ponTile.isDiscarded;
        game.pon(ponTile);
        auto ronTile = new Tile(Types.bamboo, Numbers.one);
        ronTile.isNotOwn;
        ronTile.isDiscarded;
        game.isRonnable(ronTile, metagame).should.equal(false);
    }

    void ron(Tile discard, const Metagame metagame)
    {
        if (!isRonnable(discard, metagame))
        {
            throw new IllegalClaimException(discard, "The tile could not have been ronned.");
        }
        _lastTile = discard;
        closedHand.tiles ~= discard;
    }

    @("Can the player ron")
    unittest
    {
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto ronTile = "🀡"d.convertToTiles[0];
        ronTile.isNotOwn;
        ingame.ron(ronTile, metagame);
        assert(ingame.isMahjong, "After ronning, the player should have mahjong");
        assert(ingame.lastTile == ronTile, "The player should confess they claimed the last tile");
    }

    bool canKanSteal(const Tile kanTile, const Metagame metagame) const
    {
        auto environment = destillEnvironmentForPotentialKanSteal(this, kanTile,
                metagame.leadingWind, metagame.isFirstTurn, metagame.isExhaustiveDraw);
        return isLegitMahjongClaim(kanTile, environment);        
    }

    @("Can a player steal a kan tile if they have a yaku")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto game = new Ingame(PlayerWinds.east,
                "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d);
        auto kanTile = "🀐"d.convertToTiles[0];
        kanTile.isNotOwn;
        kanTile.isDiscarded;
        game.canKanSteal(kanTile, metagame).should.equal(true);
    }

    @("Can a player not kan steal if they are furiten")
    unittest
    {
        void addTileToDiscard(Ingame game, Tile tile)
        {
            game.closedHand.tiles ~= tile;
            game.discard(tile);
        }

        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto game = new Ingame(PlayerWinds.east,
                "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d);
        auto kanTile = "🀐"d.convertToTiles[0];
        kanTile.isNotOwn;
        kanTile.isDiscarded;
        addTileToDiscard(game, "🀐"d.convertToTiles[0]);
        game.canKanSteal(kanTile, metagame).should.equal(false)
            .because("the player is furiten on the same tile");
        game = new Ingame(PlayerWinds.east, "🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘🀘"d);
        addTileToDiscard(game, "🀖"d.convertToTiles[0]);
        game.canKanSteal(kanTile, metagame).should.equal(false)
            .because("the player is furiten on another out");
    }

    @("Can a player still kan steal if they have no yaku")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto game = new Ingame(PlayerWinds.east,
                "🀐🀐🀑🀒🀓🀔🀕🀇🀇🀜🀝🀞"d);
        auto ponTile = new Tile(Types.character, Numbers.one);
        ponTile.isNotOwn;
        ponTile.isDiscarded;
        game.pon(ponTile);
        auto kanSteal = new Tile(Types.bamboo, Numbers.one);
        kanSteal.isNotOwn;
        kanSteal.isDiscarded;
        game.canKanSteal(kanSteal, metagame).should.equal(true);
    }

    void stealKanTile(Tile kanTile, const Metagame metagame)
    {
        if (!canKanSteal(kanTile, metagame))
        {
            throw new IllegalClaimException(kanTile, "The tile could not have been stolen");
        }
        kanTile.isStolenFromKan;
        _lastTile = kanTile;
        closedHand.tiles ~= kanTile;
    }

    @("After a kan steal the player is mahjong")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto kanTile = "🀡"d.convertToTiles[0];
        kanTile.isNotOwn;
        ingame.stealKanTile(kanTile, metagame);
        ingame.isMahjong.should.equal(true).because("the player stole the kan");
        ingame.lastTile.should.equal(kanTile);
        kanTile.isKanSteal.should.equal(true);
    }

    void couldHaveClaimed(const Tile tile)
    {
        if (isOwn(tile))
            return;
        _isTemporaryFuriten = _isTemporaryFuriten || .scanHandForMahjong(this, tile).isMahjong;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto ronTile = "🀡"d.convertToTiles[0];
        ingame.couldHaveClaimed(ronTile);
        ingame.isFuriten.should.equal(true);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto randomTile = "🀀"d.convertToTiles[0];
        ingame.couldHaveClaimed(randomTile);
        ingame.isFuriten.should.equal(false);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto ronTile = "🀡"d.convertToTiles[0];
        ingame.couldHaveClaimed(ronTile);
        ingame.isFuriten.should.equal(true);
        auto randomTile = "🀀"d.convertToTiles[0];
        ingame.couldHaveClaimed(randomTile);
        ingame.isFuriten.should.equal(true);
    }

    bool canDeclareClosedKan(const Tile tile) pure const @nogc nothrow
    {
        return closedHand.canDeclareClosedKan(tile);
    }

    void declareClosedKan(const Tile tile, Wall wall)
    {
        auto kanTiles = closedHand.declareClosedKan(tile);
        openHand.addKan(kanTiles);
        drawKanTile(wall);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
        auto tile = ingame.closedHand.tiles.back;
        auto initialLength = ingame.closedHand.tiles.length;
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.canDeclareClosedKan(tile).should.equal(true);
        ingame.declareClosedKan(tile, wall);
        ingame.closedHand.tiles.length.should.equal(initialLength - 3)
            .because("four tiles should have been subtracted from the hand and one added");
        ingame.openHand.amountOfKans.should.equal(1);
    }

    @("When I declare a kan, the last tile is a kan replacement")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
        auto tile = ingame.closedHand.tiles.back;
        auto initialLength = ingame.closedHand.tiles.length;
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.declareClosedKan(tile, wall);
        ingame.lastTile.isOwnedBy(ingame).should.equal(true);
        ingame.lastTile.isReplacementTileForKan.should.equal(true);
    }

    bool canPromoteToKan(const Tile tile) pure const @nogc nothrow
    {
        return openHand.canPromoteToKan(tile);
    }

    void promoteToKan(const Tile selectedTile, Wall wall)
    {
        auto tile = closedHand.removeTile(selectedTile);
        openHand.promoteToKan(tile);
        drawKanTile(wall);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡🀡"d.convertToTiles;
        auto tile = ingame.closedHand.tiles.back;
        tile.isNotOwn;
        ingame.pon(tile);
        auto initialLength = ingame.closedHand.tiles.length;
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.canPromoteToKan(ingame.closedHand.tiles.back).should.equal(true);
        ingame.promoteToKan(ingame.closedHand.tiles.back, wall);
        ingame.closedHand.tiles.length.should.equal(initialLength);
        ingame.openHand.amountOfKans.should.equal(1);
    }

    private void drawKanTile(Wall wall)
    {
        closedHand.drawKanTile(wall);
        _lastTile = closedHand.lastTile;
        _lastTile.isKanReplacementFor(this);
    }

    /*
     Functions related to the mahjong call.
     */

    bool isTenpai() const
    {
        return .isPlayerTenpai(closedHand.tiles, openHand);
    }

    bool isFuriten() @property pure const
    {
        if (_isTemporaryFuriten)
            return true;
        foreach (tile; allDiscards)
        {
            if (.scanHandForMahjong(this, tile).isMahjong)
            {
                return true;
            }
        }
        return false;
    }

    private bool _isTemporaryFuriten;

    bool canTsumo(const Metagame metagame) pure const
    {
        import mahjong.domain.yaku : determineYaku;

        if(!isOwn(_lastTile)) return false;
        auto result = .scanHandForMahjong(this);
        if(!result.isMahjong) return false;
        auto yaku = result.determineYaku(this, metagame);
        return yaku.length > 0;
    }

    @("A player can claim tsumo if they drawn their last tile")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀁🀁🀁🀅🀅🀅🀄🀄🀄🀆🀆"d);
        ingame.hasDrawnTheirLastTile;
        ingame.canTsumo(metagame).should.equal(true);
    }

    @("A player cannot claim tsumo if they are not mahjong")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east, "🀅🀄🀆🀇🀈🀉🀊🀋🀌🀍🀎🀏🀐🀑"d);
        ingame.hasDrawnTheirLastTile;
        ingame.canTsumo(metagame).should.equal(false);
    }

    @("A player cannot claim tsumo if they have no yaku")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto game = new Ingame(PlayerWinds.east,
                "🀐🀐🀐🀑🀒🀓🀔🀕🀇🀇🀜🀝🀞"d);
        auto ponTile = new Tile(Types.character, Numbers.one);
        ponTile.isNotOwn;
        ponTile.isDiscarded;
        game.pon(ponTile);
        game.hasDrawnTheirLastTile;
        game.canTsumo(metagame).should.equal(false);
    }

    @("A player cannot tsumo after they claimed a tile")
    unittest
    {
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto ponTile = "🀟"d.convertToTiles[0];
        ponTile.isNotOwn;
        ingame.pon(ponTile);
        assert(!ingame.canTsumo(metagame),
                "After a claiming a tile, the player should no longer be able to tsumo.");
    }

    @("A player cannot tsumo after a chi")
    unittest
    {
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto metagame = new Metagame([new Player], new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto ronTile = "🀡"d.convertToTiles[0];
        ronTile.isNotOwn;
        ingame.chi(ronTile, ChiCandidate(ingame.closedHand.tiles[6], ingame.closedHand.tiles[8]));
        assert(!ingame.canTsumo(metagame),
                "After a claiming a tile, the player should no longer be able to tsumo.");
    }

    bool canDeclareRiichi(const Tile potentialDiscard) const
    {
        if (_isRiichi)
            return false;
        if (!openHand.isClosedHand)
            return false;
        auto remainingTiles = closedHand.tiles.without!((a, b) => a is b)([potentialDiscard]);
        return isPlayerTenpai(remainingTiles, openHand);
    }

    @("Can declare riichi when becoming tenpai after a discard")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.canDeclareRiichi(toBeDiscardedTile).should.equal(true);
        auto toNotBeDiscardedTile = ingame.closedHand.tiles[2];
        ingame.canDeclareRiichi(toNotBeDiscardedTile).should.equal(false);
    }

    @("Cannot declare riichi when already riichi")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        ingame._isRiichi = true;
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.canDeclareRiichi(toBeDiscardedTile).should.equal(false);
    }

    @("Cannot declare riichi when having claimed a tile")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto discard = new Tile(Types.wind, Winds.east);
        discard.isNotOwn;
        ingame.pon(discard);
        auto toBeDiscardedTile = ingame.closedHand.tiles[0];
        ingame.canDeclareRiichi(toBeDiscardedTile).should.equal(false);
    }

    Tile declareRiichi(const Tile discard, const Metagame metagame)
    in(canDeclareRiichi(discard), "Can only declare riichi if it's allowed")
    {
        return declareRiichi(discard, metagame.isFirstTurn);
    }

    private Tile declareRiichi(const Tile discard, bool isFirstTurn) pure
    {
        _isRiichi = true;
        _isDoubleRiichi = isFirstTurn;
        auto discardedTile = this.discard(discard);
        _isFirstTurnAfterRiichi = true;
        return discardedTile;
    }

    @("Can I declare riichi")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.isRiichi.should.equal(false);
        ingame.declareRiichi(toBeDiscardedTile, false);
        ingame.isRiichi.should.equal(true);
        ingame.isDoubleRiichi.should.equal(false);
        ingame.closedHand.tiles.length.should.equal(13);
        ingame.discards.should.equal([toBeDiscardedTile]);
    }

    @("Is a riichi declaration in the first turn double riichi")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.declareRiichi(toBeDiscardedTile, true);
        ingame.isRiichi.should.equal(true);
        ingame.isDoubleRiichi.should.equal(true);
    }

    @("If I declare riichi, is it the first turn after riichi")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.declareRiichi(toBeDiscardedTile, false);
        ingame.isFirstTurnAfterRiichi.should.equal(true);
    }

    private bool _isRiichi;
    private bool _isDoubleRiichi;
    private bool _isFirstTurnAfterRiichi;

    bool isRiichi() @property pure const @nogc nothrow
    {
        return _isRiichi;
    }

    bool isDoubleRiichi() @property pure const @nogc nothrow
    {
        return _isDoubleRiichi;
    }

    bool isFirstTurnAfterRiichi() @property pure const @nogc nothrow
    {
        return _isFirstTurnAfterRiichi;
    }

    @("Is first turn after riichi is by default false until a riichi is declared")
    unittest
    {
        import fluent.asserts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        ingame.isFirstTurnAfterRiichi.should.equal(false);
    }

    Tile discard(const Tile discardedTile) pure
    {
        _isFirstTurnAfterRiichi = false;
        auto tile = closedHand.removeTile(discardedTile);
        _discards ~= tile;
        tile.isDiscarded;
        return tile;
    }

    @("After a discard after a riichi, it is no longer considered the first turn after riichi")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.declareRiichi(toBeDiscardedTile, false);
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.drawTile(wall);
        ingame.discard(ingame.lastTile);
        ingame.isFirstTurnAfterRiichi.should.equal(false);
    }

    private Tile _lastTile;
    const(Tile) lastTile() @property pure const @nogc nothrow
    {
        return _lastTile;
    }

    void closeHand() pure
    {
        closedHand.closeHand;
    }

    void showHand() pure
    {
        closedHand.showHand;
    }

    void drawTile(Wall wall) pure
    {
        closedHand.drawTile(wall);
        _lastTile = closedHand.lastTile;
        _lastTile.isDrawnBy(this);
        startTurn;
    }

    @("If I draw a tile, does my temporary furiten resolve?")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        auto ronTile = "🀡"d.convertToTiles[0];
        ingame.couldHaveClaimed(ronTile);
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.drawTile(wall);
        ingame.isFuriten.should.equal(false)
            .because("after drawing a tile, the temporary furiten should resolve");
    }

    @("A temporary furiten should not resolve when I am riichi")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east);
        ingame.closedHand.tiles
            = "🀀🀀🀀🀀🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d.convertToTiles;
        ingame.declareRiichi(ingame.closedHand.tiles.front, false);
        auto ronTile = "🀡"d.convertToTiles[0];
        ingame.couldHaveClaimed(ronTile);
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.drawTile(wall);
        ingame.isFuriten.should.equal(true)
            .because("when sitting riichi, a furiten does no longer resolve");
    }

    @("If I draw a tile from the wall, it is still the first turn after riichi")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        ingame.declareRiichi(toBeDiscardedTile, false);
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.drawTile(wall);
        ingame.isFirstTurnAfterRiichi.should.equal(true);
    }

    @("If I draw a tile from the wall, is it my own")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;

        auto ingame = new Ingame(PlayerWinds.east,
                "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto wall = new Wall(new DefaultGameOpts);
        wall.setUp;
        wall.dice;
        ingame.drawTile(wall);
        ingame.lastTile.isOwnedBy(ingame).should.equal(true);
        ingame.lastTile.isSelfDraw.should.equal(true);
    }

    private void startTurn() pure @nogc nothrow
    {
        if (!_isRiichi)
        {
            _isTemporaryFuriten = false;
        }
    }

    private bool isLegitMahjongClaim(const Tile tile, const Environment environment) const
    {
        import mahjong.domain.result : isMahjongWithYaku;

        if (isFuriten)
            return false;
        auto result = scanHandForMahjong(this, tile);
        return result.isMahjongWithYaku(environment);
    }
}

bool doesDiscardsOnlyContain(Ingame game, const ComparativeTile discard) pure @nogc nothrow
{
    return game.discards.length == 1 && game.discards[0].hasEqualValue(discard);
}

unittest
{
    import fluent.asserts;

    auto ingame = new Ingame(PlayerWinds.east);
    auto discard = ComparativeTile(Types.wind, Winds.east);
    ingame.doesDiscardsOnlyContain(discard).should.equal(false).because("there are no discards");
    ingame.setDiscards([new Tile(Types.wind, Winds.east)]);
    ingame.doesDiscardsOnlyContain(discard).should.equal(true).because("the only discard matches");
    auto otherDiscard = ComparativeTile(Types.wind, Winds.west);
    ingame.doesDiscardsOnlyContain(otherDiscard).should.equal(false)
        .because("the discard does not match");
    ingame.setDiscards([new Tile(Types.wind, Winds.east), new Tile(Types.wind, Winds.east)]);
    ingame.doesDiscardsOnlyContain(discard).should.equal(false)
        .because("there are multiple discards");
}

bool hasAllTheKans(const Ingame game, int maxAmountOfKans) pure @nogc nothrow
{
    return game.openHand.hasAllKans(maxAmountOfKans);
}

bool canDiscard(const Ingame game, const Tile potentialDiscard) pure @nogc nothrow
{
    if (game.isRiichi)
    {
        return game.lastTile is potentialDiscard;
    }
    return true;
}

@("Can discard every tile when not riichi")
unittest
{
    import fluent.asserts;

    auto ingame = new Ingame(PlayerWinds.east,
            "🀀🀁🀂🀃🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d);
    foreach (tile; ingame.closedHand.tiles)
    {
        ingame.canDiscard(tile).should.equal(true);
    }
}

@("Can only discard the most recently drawn tile when riichi")
unittest
{
    import fluent.asserts;

    auto ingame = new Ingame(PlayerWinds.east,
            "🀀🀁🀂🀃🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d);
    ingame._isRiichi = true;
    ingame._lastTile = ingame.closedHand.tiles[$ - 1];
    ingame.canDiscard(ingame.lastTile).should.equal(true);
    foreach (tile; ingame.closedHand.tiles[0 .. $ - 1])
    {
        ingame.canDiscard(tile).should.equal(false);
    }
}

bool isEligibleForRedraw(const Ingame game, const Metagame metagame) pure @nogc nothrow
{
    return isEligibleForRedraw(game, metagame.isFirstTurn);
}

private bool isEligibleForRedraw(const Ingame game, bool isFirstTurn) pure @nogc nothrow
{
    return isFirstTurn && game.closedHand.hasNineOrMoreUniqueHonoursOrTerminals;
}

@("If a player has 9 or more honours or terminals in the first turn, they may redraw")
unittest
{
    import fluent.asserts;

    auto ingame = new Ingame(PlayerWinds.east,
            "🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d);
    isEligibleForRedraw(ingame, true).should.equal(true);
}

@("If a player has 9 or more honours or terminals in a later turn, they are out of luck")
unittest
{
    import fluent.asserts;

    auto ingame = new Ingame(PlayerWinds.east,
            "🀀🀁🀂🀃🀄🀅🀆🀇🀏🀝🀟🀟🀠🀠"d);
    isEligibleForRedraw(ingame, false).should.equal(false);
}

@("If a player has less than 9 honours or terminals in the first turn, they may not redraw")
unittest
{
    import fluent.asserts;

    auto ingame = new Ingame(PlayerWinds.east,
            "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    isEligibleForRedraw(ingame, true).should.equal(false);
}
