module mahjong.domain.player;

import std.algorithm : map;
import std.array : array;
import std.experimental.logger;
import std.uuid;

import mahjong.domain;
import mahjong.domain.enums;
import mahjong.domain.scoring;

class Player
{ // General variables.
	const UUID id;
	const dstring name = "Cal"d;

	int playLoc = -10;
	private int _score;
	int score() @property pure const
	{
		return _score;
	}

	Ingame game; // Resets after every round.
	alias game this;

    version(mahjong_test)
    {
        this()
        {
            this("🀀🀁🀂🀃🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d);            
        }

        this(dstring tiles)
        {
            this(tiles, PlayerWinds.autumn);
        }

        this(dstring tiles, PlayerWinds wind)
        {
            this(30_000);
            game = new Ingame(wind, tiles);
            game.hasDrawnTheirLastTile;
        }
    }

	this(int initialScore)
	{
		id = randomUUID;
		_score = initialScore;
	}

	void startGame(PlayerWinds wind)
	{
		trace("Starting game for ", wind);
		game = new Ingame(wind);
	}

	int wind() @property pure const
	{
		if(game is null) return -1;
		return game.wind;
	}

	bool isChiable(const Tile discard, const Metagame metagame) pure const
	{
		if(metagame.nextPlayer !is this) return false;
		return game.isChiable(discard);
	}

    @("Can I chi if and only if I'm the next player")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.creation;
        import mahjong.domain.opts;
        auto player = new Player();
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
        auto player2 = new Player();
        player2.startGame(PlayerWinds.south);
        auto player3 = new Player();
        player3.startGame(PlayerWinds.west);
        auto metagame = new Metagame([player, player2, player3], new DefaultGameOpts);
        metagame.currentPlayer = player3;
        auto chiableTile = "🀕"d.convertToTiles[0];
        chiableTile.isDrawnBy(player3);
        player.isChiable(chiableTile, metagame).should.equal(true);
        metagame.currentPlayer = player2;
        chiableTile.isDrawnBy(player2);
        player.isChiable(chiableTile, metagame).should.equal(false)
            .because("a player cannot chi a tile when they are not the next player");
    }

    bool canDeclareRiichi(const Tile potentialDiscard, const Metagame metagame) const
    {
        return metagame.canRiichiBeDeclared && game.canDeclareRiichi(potentialDiscard);
    }

    Tile declareRiichi(const Tile discard, Metagame metagame)
    in(canDeclareRiichi(discard, metagame), "Can only declare riichi if it's allowed")
    {
        _score -= metagame.riichiFare;
        metagame.riichiIsDeclared;
        return game.declareRiichi(discard, metagame);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;
        auto player = new Player(30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.wall = new Wall(new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        player.game = ingame;
        player.isRiichi.should.equal(false);
        player.declareRiichi(toBeDiscardedTile, metagame);
        player.isRiichi.should.equal(true);
        player.score.should.equal(29_000);
        metagame.amountOfRiichiSticks.should.equal(1);
    }

    void abortGame(Metagame metagame)
    {
        if(isRiichi)
        {
            _score += metagame.riichiFare;
        }
    }

    @("If the player is not riichi, an aborted game has no effect")
    unittest
    {
        import fluent.asserts;
        auto player = new Player(30_000);
        player.game = new Ingame(PlayerWinds.east);
        player.abortGame(null);
        player.score.should.equal(30_000);
    }

    @("If the player is riichi, the aborted game resets the riichi.")
    unittest
    {
        import fluent.asserts;
        import mahjong.domain.opts;
        auto player = new Player(30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        player.game = ingame;
        player.declareRiichi(toBeDiscardedTile, metagame);
        player.abortGame(metagame);
        player.score.should.equal(30_000);
    }

	void applyTransaction(const Transaction transaction)
	in
	{
		assert(transaction.player == this, "The transaction was applied to the wrong player.");
	}
	body
	{
		_score += transaction.amount;
	}

    unittest
    {
        auto player = new Player(30_000);
        auto transaction = new Transaction(player, 5000);
        player.applyTransaction(transaction);
        assert(player.score == 35_000, "The amount should have been added to the player's score.");
    }

    unittest
    {
        auto player = new Player(30_000);
        auto transaction = new Transaction(player, -5000);
        player.applyTransaction(transaction);
        assert(player.score == 25_000, "The amount should have been subtracted from the player's score.");
    }

    unittest
    {
        import core.exception;
        import std.exception;
        auto player1 = new Player();
        auto player2 = new Player();
        auto transaction = new Transaction(player2, 5000);
        assertThrown!AssertError(player1.applyTransaction(transaction), "Applying someone else's transaction should not be allowed.");
    }
}
