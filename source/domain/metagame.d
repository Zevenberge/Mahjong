module mahjong.domain.metagame;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.random;
import std.range;
import std.conv;
import std.uuid;

import mahjong.domain.enums;
import mahjong.domain;
import mahjong.domain.wrappers;
import mahjong.engine.flow.mahjong;
import mahjong.engine.mahjong;
import mahjong.engine.opts;
import mahjong.engine.scoring;
import mahjong.share.range;

class Metagame
{
	Player[] players; 

	const(Player) currentPlayer() @property pure const
	{ 
		return _turn == -1 ? null : players[_turn]; 
	}

	Player getCurrentPlayer() pure
	{
		return _turn == -1 ? null : players[_turn]; 
	}

	Player currentPlayer(Player player) @property
	{
		_turn = players.indexOf(player);
		return player;
	}

	const(Player) nextPlayer() @property pure const
	{
		return players[(_turn+1)%$];
	}

	auto otherPlayers() 
	{
		auto currentPlayer = this.currentPlayer;
		return players.filter!(p => p != currentPlayer);
	}

	auto otherPlayers(const Player player) const
	{
		return players.filter!(p => p != player);
	}

	AmountOfPlayers amountOfPlayers() @property pure const
	{
		return AmountOfPlayers(players.length);
	}

	Wall wall;
	private PlayerWinds _leadingWind;
	PlayerWinds leadingWind() @property pure const
	{
		return _leadingWind;
	}
	private const Player _initialEastPlayer;
	private int _initialWind;

	private uint _round = 1;
	uint round() @property pure const
	{
		return _round;
	}

	private size_t _counters = 0;
	size_t counters() @property pure const
	{
		return _counters;
	}

	this(Player[] players, const Opts opts)
	{
		this.players = players;
        _opts = opts;
		info("Initialising metagame");
		placePlayers;
		_initialWind = uniform(0, players.length).to!int; 
		_initialEastPlayer = getEastPlayer;
		_leadingWind = PlayerWinds.east;
		info("Initialised metagame");
	}

	private Player getEastPlayer()
	{
		return players[($-_initialWind)%$];
	}

	private void placePlayers()
	{ 
		foreach(i, player; players)
		{
			trace("Placing player \"", player.name.to!string, "\" (", i, ")");
			player.playLoc = i.to!int;
		}
	}

	void initializeRound()
	in
	{
		assert(!isGameOver, "Cannot start a new round when the game is over.");
	}
	body
	{
		info("Initializing the next round");
		startPlayersGame;
		setUpWall;
		removeTurnPlayer;
        _isRedrawDeclared = false;
	}

    @("If the game is aborted due to a redraw, a redraw should no longer be requested")
    unittest
    { 
        import fluent.asserts;
        import mahjong.engine.creation;
        import mahjong.engine.flow;
        auto player1 = new Player();
        auto player2 = new Player();
        auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
        metagame.declareRedraw;
        metagame.abortRound;
        metagame.initializeRound;
        metagame.beginRound;
        metagame.isAbortiveDraw.should.equal(false);
    }

	private void startPlayersGame()
	{
		foreach(int i, player; players)
		{ 
			auto wind = ((_initialWind + i) % players.length).to!PlayerWinds;
			player.startGame(wind);
		}
	}
	
	private void removeTurnPlayer()
	{
		_turn = -1;
	}

	private void setUpWall()
	{
		wall = getWall;
		wall.setUp;
	}

	protected Wall getWall()
	{
		return new Wall(_opts);
	}

	void beginRound()
	{
		wall.dice;
		distributeTiles;
		setTurnPlayerToEast;
        _isFirstTurn = true;
	}

	private void distributeTiles()
	{
		for(int i = 0; i < 3; ++i)
		{
			distributeXTiles(4);
		}
		distributeXTiles(1);
	}

	private void distributeXTiles(int amountOfTiles)
	{
		foreach(player; players)
		{ // TODO: update such that distribution begins with East.
			for(int i = 0; i < amountOfTiles; ++i)
			{
				player.drawTile(wall);
			}
		}
	}

	void finishRound()
	{
		++_round;
		auto data = this.constructMahjongData;
		applyTransactions(data);
		moveWinds;
        _amountOfRiichiSticks = 0;
	}

    @("End of a round should reset the counters")
    unittest
    {
        import fluent.asserts;
        auto winningGame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
        auto losingGame = new Ingame(PlayerWinds.west, "🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
        auto player1 = new Player;
        player1.game = winningGame;
        player1.hasDrawnTheirLastTile;
        auto metagame = new Metagame([player1], new DefaultGameOpts);
        metagame.setUpWall;
        metagame.currentPlayer = player1;
        metagame.riichiIsDeclared;
        metagame.finishRound;
        metagame.amountOfRiichiSticks.should.equal(0);
    }

	private void applyTransactions(const(MahjongData)[] data)
	{
		auto transactions = data.toTransactions(this);
		foreach(transaction; transactions)
		{
			auto player = players.first!(p => p == transaction.player);
			player.applyTransaction(transaction);
		}
	}

	private void moveWinds()
	{
		if(!needToMoveWinds) 
		{
			++_counters;
			return;
		}
		_counters = 0;
		_initialWind = ((_initialWind - 1 + players.length) % players.length).to!int;
		if(_initialEastPlayer == getEastPlayer)
		{
			_leadingWind = (_leadingWind + 1).to!PlayerWinds;
			_round = 1;
		}
	}

	private bool needToMoveWinds()
	{
		return !players.first!(p => p.isEast).isMahjong;
	}

    void abortRound()
    {
        foreach(player; players)
        {
            player.abortGame(this);
            if(player.isRiichi) _amountOfRiichiSticks--;
        }
    }

    @("During an abortive draw, nothing happens")
    unittest
    {
        import fluent.asserts;
        import mahjong.engine.flow.eventhandler;
        auto players = [new Player(new TestEventHandler, 30_000), 
            new Player(new TestEventHandler, 30_000)];
        auto metagame = new Metagame(players, new DefaultGameOpts);
        metagame.initializeRound;
        metagame._counters = 5;
        metagame.abortRound;
        metagame.amountOfRiichiSticks.should.equal(0);
        metagame.counters.should.equal(5);
        players[0].score.should.equal(30_000);
        players[1].score.should.equal(30_000);
    }

    @("If a player is riichi, it will be undone")
    unittest
    {
        import fluent.asserts;
        import mahjong.engine.flow.eventhandler;
        auto players = [new Player(new TestEventHandler, 30_000), 
            new Player(new TestEventHandler, 30_000)];
        auto metagame = new Metagame(players, new DefaultGameOpts);
        metagame.initializeRound;
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        players[0].game = ingame;
        players[0].declareRiichi(toBeDiscardedTile, metagame);
        metagame.abortRound;
        metagame.amountOfRiichiSticks.should.equal(0);
        metagame.counters.should.equal(0);
        players[0].score.should.equal(30_000);
    }

    @("If a player is riichi, the amount of riichi sticks will be reduced by one for each riichi")
    unittest
    {
        import fluent.asserts;
        import mahjong.engine.flow.eventhandler;
        auto players = [new Player(new TestEventHandler, 30_000), 
            new Player(new TestEventHandler, 30_000)];
        auto metagame = new Metagame(players, new DefaultGameOpts);
        metagame.initializeRound;
        metagame._amountOfRiichiSticks = 5;
        auto ingame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        auto toBeDiscardedTile = ingame.closedHand.tiles[3];
        players[0].game = ingame;
        players[0].declareRiichi(toBeDiscardedTile, metagame);
        metagame.abortRound;
        metagame.amountOfRiichiSticks.should.equal(5);
    }

	bool isGameOver()
	{
		return _leadingWind > _opts.finalLeadingWind;
	}
	/*
	 The game itself.
	 */

	private size_t _turn = 0; 

	private void setTurnPlayerToEast() 
	{
		foreach(i, player; players)
		{
			if(player.isEast)
			{
				_turn = i.to!int;
				break;
			}
		}
	}

    void riichiIsDeclared()
    {
        _amountOfRiichiSticks++;
    }

    int amountOfRiichiSticks() @property pure const
    {
        return _amountOfRiichiSticks;
    }

    private int _amountOfRiichiSticks;

	void tsumo()	
	{
		flipOverWinningTiles();	
	}

	void advanceTurn()
	{
		if(isExhaustiveDraw)
		{
			info("Exhaustive draw reached.");
			exhaustiveDraw;
		}
		else
		{
			trace("Advancing turn.");
			_turn = (_turn + 1) % players.length;
            if(currentPlayer is _initialEastPlayer)
            {
                _isFirstTurn = false;
            }
		}
	}

    private bool _isFirstTurn;

    bool isFirstTurn() @property pure const
    {
        return _isFirstTurn;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.flow;
        auto player = new Player(new TestEventHandler, 30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        metagame.isFirstTurn.should.equal(true);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.flow;
        auto player = new Player(new TestEventHandler, 30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        metagame.advanceTurn;
        metagame.isFirstTurn.should.equal(false)
            .because("all players already had a turn");
    }

    void aTileHasBeenClaimed()
    {
        _isFirstTurn = false;
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.flow;
        auto player = new Player(new TestEventHandler, 30_000);
        auto metagame = new Metagame([player], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        metagame.aTileHasBeenClaimed;
        metagame.isFirstTurn.should.equal(false)
            .because("all players already had a turn");
    }

	bool isAbortiveDraw() @property
	{
		return _isRedrawDeclared
            || didAllPlayersDiscardTheSameWindInTheFirstTurn
            || areAllKansDeclaredAndNotByOnePlayer
            || isEveryPlayerRiichi;
	}

    private bool didAllPlayersDiscardTheSameWindInTheFirstTurn()
    {
        if(!_isFirstTurn) return false;
        auto firstPlayer = players[0];
        if(firstPlayer.discards.length != 1) return false;
        auto firstPlayersDiscard = firstPlayer.discards[0];
        if(!firstPlayersDiscard.isWind) return false;
        return players[1..$].all!(player => player.doesDiscardsOnlyContain(firstPlayersDiscard));
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.domain.enums;
        auto player1 = new Player();
        auto player2 = new Player();
        auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        player1.setDiscards([new Tile(Types.wind, Winds.east)]);
        player2.setDiscards([new Tile(Types.wind, Winds.east)]);
        metagame.isAbortiveDraw.should.equal(true)
            .because("all players discarded the same wind in the first round");
        metagame.aTileHasBeenClaimed;
        metagame.isAbortiveDraw.should.equal(false)
            .because("the first round has been interrupted");
    }

    private bool areAllKansDeclaredAndNotByOnePlayer()
    {
        if(!wall.isMaxAmountOfKansReached) return false;
        return !players.any!(player => player.hasAllTheKans(_opts.maxAmountOfKans));
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.creation;
        auto player1 = new Player();
        auto player2 = new Player();
        auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
        void kan(Player player)
        {
            player.game.closedHand.tiles = "🀕🀕🀕"d.convertToTiles;
            auto kannableTile = "🀕"d.convertToTiles[0];
            kannableTile.origin = new Ingame(PlayerWinds.north);
            player.kan(kannableTile, metagame.wall);
        }
        metagame.initializeRound;
        metagame.beginRound;
        kan(player1);
        kan(player1);
        kan(player2);
        kan(player2);
        metagame.isAbortiveDraw.should.equal(true)
            .because("two players shares all available kans");

        metagame.initializeRound;
        metagame.beginRound;
        kan(player1);
        kan(player1);
        kan(player1);
        kan(player1);
        metagame.isAbortiveDraw.should.equal(false)
            .because("one player claimed all available kans");
    }

    private bool isEveryPlayerRiichi()
    {
        return players.all!(player => player.isRiichi);
    }

    unittest
    {
        import fluent.asserts;
        import mahjong.engine.creation;
        import mahjong.engine.flow;
        auto player1 = new Player();
        auto player2 = new Player();
        auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
        metagame.initializeRound;
        metagame.beginRound;
        player1.game = new Ingame(PlayerWinds.east, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        player2.game = new Ingame(PlayerWinds.south, "🀀🀀🀀🀆🀙🀙🀙🀟🀟🀠🀠🀡🀡🀡"d);
        player1.declareRiichi(player1.closedHand.tiles[3], metagame);
        metagame.isAbortiveDraw.should.equal(false);
        player2.declareRiichi(player2.closedHand.tiles[3], metagame);
        metagame.isAbortiveDraw.should.equal(true);
    }

    void declareRedraw()
    {
        _isRedrawDeclared = true;
    }
    private bool _isRedrawDeclared;

    @("If a redraw is declared, the game is aborted")
    unittest
    { 
        import fluent.asserts;
        import mahjong.engine.creation;
        import mahjong.engine.flow;
        auto player1 = new Player();
        auto player2 = new Player();
        auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
        metagame.declareRedraw;
        metagame.isAbortiveDraw.should.equal(true);
    }

    bool canRiichiBeDeclared() @property const
    {
        return wall.canRiichiBeDeclared;
    }

	bool isExhaustiveDraw() @property const
	{
        return wall.isExhaustiveDraw;
	}

	deprecated("Move to exhaustive draw flow.")
	private void exhaustiveDraw()
	{
		checkNagashiMangan;
		checkTenpai;
	}
	
	private void checkNagashiMangan()
	{
		foreach(player; players)
		{
			if(player.isNagashiMangan)
			{
				// Go ro results screen.
				info("Nagashi Mangan!");
			}
		}
	}
	private void checkTenpai()
	{
		foreach(player; players)
		{
			if(player.isTenpai)
			{
				player.showHand;
				info(player.wind, " is tenpai!");
			}
			else
			{
				player.closeHand;
			}
		}
	}

    private void flipOverWinningTiles()
	{
		foreach(player; players)
		{
			if(player.isMahjong)
				player.showHand;
			else
				player.closeHand; 
		}
	}

    private const Opts _opts;

    int riichiFare() pure const
    {
        return _opts.riichiFare;
    }

    GameMode gameMode() pure const
    {
        return _opts.gameMode;
    }
}

unittest
{
	import mahjong.engine.flow;
	auto player = new Player();
	auto player2 = new Player();
	auto player3 = new Player();
	auto metagame = new Metagame([player, player2, player3], new DefaultGameOpts);
	metagame.currentPlayer = player;
	assert(metagame.currentPlayer == player, "The current player should be set and identical to the value set");
	assert(metagame.nextPlayer == player2, "If it is player 1's turn, player 2 should be next.");
	metagame.currentPlayer = player3;
	assert(metagame.nextPlayer == player, "If it is player 3's turn, the next player should loop back to 1");
}

unittest
{
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	auto player1 = new Player();
	auto player2 = new Player();
	auto players = [player1, player2];
	auto metagame = new Metagame(players, new DefaultBambooOpts);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = players[metagame._initialWind];
	eastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	assert(eastPlayer.isEast, "the east player was mahjong, the turns should not have advanced");
	assert(1 == metagame.counters, "A counter should have been placed");
}

unittest
{
	import mahjong.engine.creation;
	auto player1 = new Player();
	auto player2 = new Player();
	auto players = [player1, player2];
	auto metagame = new Metagame(players, new DefaultBambooOpts);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = players[metagame._initialWind];
	auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
	nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	assert(nonEastPlayer.isEast, "the non east player was mahjong, the turns should have advanced");
	assert(!eastPlayer.isEast, "the non east player was mahjong, the turns should have advanced");
	assert(metagame.round == 2, "The round counter should have been upped.");
	assert(metagame.counters == 0, "As the turn advanced, there are no more counters");
}

unittest
{
	import mahjong.engine.creation;
	auto player1 = new Player();
	auto player2 = new Player();
	auto players = [player1, player2];
	auto metagame = new Metagame(players, new DefaultBambooOpts);
	metagame.initializeRound;
	metagame.beginRound;
	foreach(i; 0..2)
	{
		auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
		nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
		metagame.finishRound;
		metagame.initializeRound;
		metagame.beginRound;
	}
	assert(metagame.leadingWind == PlayerWinds.south, "After the first east player becomes east again, the leading wind should swap.");
	assert(metagame.round == 1, "The round should have been reset");
}

unittest
{
	import mahjong.engine.creation;
	auto player1 = new Player();
	auto player2 = new Player();
	auto player3 = new Player();
	auto player4 = new Player();
	auto players = [player1, player2, player3, player4];
	auto metagame = new Metagame(players, new DefaultBambooOpts);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = metagame.currentPlayer;
	auto southPlayer = metagame.nextPlayer;
	assert(southPlayer.wind == PlayerWinds.south, "Sanity check");
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	assert(southPlayer.isEast, "the south player was mahjong, the turns should have advanced such that the south player is now east");
	assert(!eastPlayer.isEast, "the non east player was mahjong, the turns should have advanced");
	assert(eastPlayer.wind == PlayerWinds.north, "east is degraded to north");
}

unittest
{
	import mahjong.engine.creation;
	auto player1 = new Player();
	auto player2 = new Player();
	auto player3 = new Player();
	auto player4 = new Player();
	auto players = [player1, player2, player3, player4];
	auto metagame = new Metagame(players, new DefaultBambooOpts);
	metagame.initializeRound;
	metagame.beginRound;
	foreach(i; 0..3)
	{
		metagame.finishRound;
		metagame.initializeRound;
		metagame.beginRound;
	}
	assert(metagame.leadingWind == PlayerWinds.east, "With three east losses, the leading wind should not have changed");
	assert(metagame.round == 4, "we are going to the fourth east round.");
}

unittest
{
	import mahjong.engine.creation;
	auto player1 = new Player();
	auto player2 = new Player();
	auto players = [player1, player2];
	auto metagame = new Metagame(players, new DefaultBambooOpts);
	metagame.initializeRound;
	metagame.beginRound;
	auto eastPlayer = players[metagame._initialWind];
	eastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	metagame.initializeRound;
	metagame.beginRound;
	// East does not win.
	metagame.finishRound;
	assert(metagame.counters == 0, "The amount of counters should have been reset");
}

unittest
{
	import core.exception;
	import std.exception;
	import mahjong.engine.creation;
	auto player1 = new Player();
	auto player2 = new Player();
	auto player3 = new Player();
	auto player4 = new Player();
	auto players = [player1, player2, player3, player4];
	auto metagame = new Metagame(players, new DefaultGameOpts);
	metagame.initializeRound;
	metagame.beginRound;
	foreach(i; 0..7)
	{
		auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
		nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
		metagame.finishRound;
		assert(!metagame.isGameOver, "There are still turns left to play!");
		metagame.initializeRound;
		metagame.beginRound;
	}
	auto nonEastPlayer = players[(metagame._initialWind + 1)%$];
	nonEastPlayer.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d.convertToTiles;
	metagame.finishRound;
	assert(metagame.isGameOver, "The game should have been finished after 2x 4 rounds of non-east wins.");
	assertThrown!AssertError(metagame.initializeRound, "Attempting to start a new round should be blocked");

}

class BambooMetagame : Metagame
{
	this(Player[] players, const Opts gameOpts)
	{
		super(players, gameOpts);
	}

	override Wall getWall()
	{
		return new BambooWall(_opts);
	}
}

void notifyPlayersAboutMissedTile(Metagame metagame, const Tile tile)
{
    foreach(player; metagame.players)
    {
        player.couldHaveClaimed(tile);
    }
}

auto playersByTurnOrder(Metagame metagame) @property
{
    return metagame.players.cycle
        .find(metagame.getCurrentPlayer)
        .atLeastOneUntil(metagame.getCurrentPlayer);
}

unittest
{
    import fluent.asserts;
    auto player1 = new Player;
    auto player2 = new Player;
    auto player3 = new Player;
    auto player4 = new Player;
    auto metagame = new Metagame([player1, player2, player3, player4], new DefaultGameOpts);
    metagame.currentPlayer = player3;
    metagame.playersByTurnOrder.should.equal(
        [player3, player4, player1, player2]
        );
}

const(MahjongData)[] constructMahjongData(Metagame metagame)
{
    return metagame.playersByTurnOrder.map!((player){
            auto mahjongResult = scanHandForMahjong(player);
            return MahjongData(player, mahjongResult);
        }).filter!(data => data.result.isMahjong).array;
}

unittest
{
    import fluent.asserts;
    auto winningGame = new Ingame(PlayerWinds.east, "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀞🀟"d);
    auto losingGame = new Ingame(PlayerWinds.west, "🀀🀁🀂🀃🀄🀆🀅🀇🀏🀐🀘🀙🀡🀊"d);
    auto player1 = new Player;
    player1.game = winningGame;
    auto player2 = new Player;
    player2.game = losingGame;
    auto player3 = new Player;
    player3.game = winningGame;
    auto player4 = new Player;
    player4.game = losingGame;
    auto metagame = new Metagame([player1, player2, player3, player4], new DefaultGameOpts);
    metagame.currentPlayer = player2;
    auto mahjongData = metagame.constructMahjongData;
    mahjongData.length.should.equal(2);
    mahjongData[0].player.should.equal(player3);
    mahjongData[1].player.should.equal(player1);
}

int riichiFare(const Metagame metagame) @property
{
    return metagame._opts.riichiFare;
}