module mahjong.domain.player;

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

	this(GameEventHandler eventHandler)
	{
		id = randomUUID;
		_score = gameOpts.initialScore;
		this.eventHandler = eventHandler;
	}
	this(GameEventHandler eventHandler, dstring name)
	{
		this.name = name;
		this(eventHandler);
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
        gameOpts = new DefaultGameOpts;
        auto player = new Player(new TestEventHandler);
        player.startGame(PlayerWinds.east);
        player.game.closedHand.tiles = "🀓🀔"d.convertToTiles;
        auto player2 = new Player(new TestEventHandler);
        player2.startGame(PlayerWinds.south);
        auto player3 = new Player(new TestEventHandler);
        player3.startGame(PlayerWinds.west);
        auto metagame = new Metagame([player, player2, player3]);
        metagame.currentPlayer = player3;
        auto chiableTile = "🀕"d.convertToTiles[0];
        chiableTile.origin = player3;
        player.isChiable(chiableTile, metagame).should.equal(true);
        metagame.currentPlayer = player2;
        chiableTile.origin = player2;
        player.isChiable(chiableTile, metagame).should.equal(false)
            .because("a player cannot chi a tile when they are not the next player");
    }

    void declareRiichi(const Tile discard, const Metagame metagame)
    {
        _score -= gameOpts.riichiFare;
        game.declareRiichi(discard, metagame);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.opts;
        scope(exit) gameOpts = null;
        gameOpts = new DefaultGameOpts;
        auto player = new Player(new TestEventHandler);
        auto metagame = new Metagame([player]);
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        player.game = ingame;
        player.isRiichi.should.equal(false);
        player.declareRiichi(toBeDiscardedTile, metagame);
        player.isRiichi.should.equal(true);
        player.score.should.equal(29_000);
    }

	void drawTile(Wall wall)
	{
		this.game.drawTile(wall);
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
        gameOpts = new DefaultGameOpts;
        auto player = new Player(new TestEventHandler);
        auto transaction = new Transaction(player, 5000);
        player.applyTransaction(transaction);
        assert(player.score == 35000, "The amount should have been added to the player's score.");
    }

    unittest
    {
        gameOpts = new DefaultGameOpts;
        auto player = new Player(new TestEventHandler);
        auto transaction = new Transaction(player, -5000);
        player.applyTransaction(transaction);
        assert(player.score == 25000, "The amount should have been subtracted from the player's score.");
    }

    unittest
    {
        import core.exception;
        import std.exception;
        gameOpts = new DefaultGameOpts;
        auto player1 = new Player(new TestEventHandler);
        auto player2 = new Player(new TestEventHandler);
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
		return(format("%s-san",name));
	}
}



