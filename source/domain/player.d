module mahjong.domain.player;

import std.algorithm : map;
import std.array : array;
import std.experimental.logger;
import std.string;
import std.uuid;

import mahjong.domain.enums;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow;
import mahjong.engine.opts;
import mahjong.engine.scoring;

class Player
{ // General variables.
	const UUID id;
	dstring name = "Cal"d;

	int playLoc = -10;
	private int _score;
	int score() @property pure const
	{
		return _score;
	}

	Ingame game; // Resets after every round.
	alias game this;
	GameEventHandler eventHandler; // Allows for distribution of the flow logic

    version(unittest)
    {
        this()
        {
            this(new TestEventHandler, 30_000);
            game = new Ingame(PlayerWinds.autumn, "🀀🀁🀂🀃🀄🀄🀆🀆🀇🀏🀐🀘🀙🀡"d);
            game.hasDrawnTheirLastTile;
        }
    }

	this(GameEventHandler eventHandler, int initialScore)
	{
		id = randomUUID;
		_score = initialScore;
		this.eventHandler = eventHandler;
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
		if(metagame.nextPlayer.id != this.id) return false;
		return game.isChiable(discard);
	}

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.creation;
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
        chiableTile.origin = player3;
        player.isChiable(chiableTile, metagame).should.equal(true);
        metagame.currentPlayer = player2;
        chiableTile.origin = player2;
        player.isChiable(chiableTile, metagame).should.equal(false)
            .because("a player cannot chi a tile when they are not the next player");
    }

    bool canDeclareRiichi(const Tile potentialDiscard, const Metagame metagame) const
    {
        return metagame.canRiichiBeDeclared && game.canDeclareRiichi(potentialDiscard);
    }

    Tile declareRiichi(const Tile discard, Metagame metagame)
    {
        _score -= metagame.riichiFare;
        metagame.riichiIsDeclared;
        return game.declareRiichi(discard, metagame);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.opts;
        auto player = new Player(new TestEventHandler, 30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        player.game = ingame;
        player.isRiichi.should.equal(false);
        player.declareRiichi(toBeDiscardedTile, metagame);
        player.isRiichi.should.equal(true);
        player.score.should.equal(29_000);
        metagame.amountOfRiichiSticks.should.equal(1);
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
        auto player = new Player(new TestEventHandler, 30_000);
        auto transaction = new Transaction(player, 5000);
        player.applyTransaction(transaction);
        assert(player.score == 35000, "The amount should have been added to the player's score.");
    }

    unittest
    {
        auto player = new Player(new TestEventHandler, 30_000);
        auto transaction = new Transaction(player, -5000);
        player.applyTransaction(transaction);
        assert(player.score == 25000, "The amount should have been subtracted from the player's score.");
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

	override bool opEquals(Object o)
	{
		auto p = cast(Player)o;
		if(p is null) return false;
		return p.id == id;
	}

	override string toString() const
	{
		return(format("%s (%s)", id, name));
	}
}

Player[] createPlayers(GameEventHandler[] eventHandlers, Opts opts)
{
    return eventHandlers.map!(d => new Player(d, opts.initialScore)).array;
}
