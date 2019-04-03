module mahjong.engine.flow.mahjong;

import std.algorithm;
import std.array;
import std.conv;
import std.experimental.logger;
import mahjong.domain.enums;
import mahjong.domain.metagame;
import mahjong.engine.mahjong;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class MahjongFlow : WaitForEveryPlayer!MahjongEvent
{
	this(Metagame game, INotificationService notificationService)
	{
		trace("Constructing mahjong flow");
        _mahjongData = game.constructMahjongData;
		super(game, notificationService);
        trace("Finished constructing mahjong flow");
	}

    private const(MahjongData[]) _mahjongData;

    protected override MahjongEvent createEvent()
    {
        return new MahjongEvent(_metagame, _mahjongData);
    }

    protected override void advance()
    {
        _metagame.finishRound;
        mixin(switchToNextRoundOrGameOver);
        
    }
}

enum switchToNextRoundOrGameOver =
q{
	if(_metagame.isGameOver)
	{
		switchFlow(new GameEndFlow(_metagame, _notificationService));
		return;
	}
	switchFlow(new RoundStartFlow(_metagame, _notificationService));
};

class MahjongEvent
{
	this(const Metagame metagame,
		const(MahjongData)[] data)
	{
		_data = data;
		this.metagame = metagame;
	}

	const Metagame metagame;

	private const(MahjongData)[] _data;
	const(MahjongData)[] data() @property
	{
		return _data;
	}

	private bool _isHandled;
	bool isHandled() @property
	{
		return _isHandled;
	}

	void handle()
	{
		_isHandled = true;
	}
}

unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
    import mahjong.domain.player;
	import mahjong.engine.creation;
    import mahjong.engine.opts;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler, 30_000);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto metagame = new Metagame([player1], new DefaultGameOpts);
	auto flow = new MahjongFlow(metagame, new NullNotificationService);
	assert(eventhandler.mahjongEvent.data.length == 1, "As the only player has a mahjong, one data should be added");
}
unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
    import mahjong.domain.player;
	import mahjong.engine.creation;
    import mahjong.engine.opts;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler, 30_000);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto player2 = new Player();
	player2.game = new Ingame(PlayerWinds.south);
	player2.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d.convertToTiles;
	auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
	auto flow = new MahjongFlow(metagame, new NullNotificationService);
	assert(eventhandler.mahjongEvent.data.length == 1, "As only one of two players has a mahjong, one data should be added");
	assert(eventhandler.mahjongEvent.data[0].player == player1, "The mahjong player is player 1");
}
unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
    import mahjong.domain.player;
	import mahjong.engine.creation;
    import mahjong.engine.opts;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler, 30_000);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto player2 = new Player();
	player2.game = new Ingame(PlayerWinds.south);
	player2.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d.convertToTiles;
	auto player3 = new Player();
	player3.game = new Ingame(PlayerWinds.west);
	player3.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto metagame = new Metagame([player1, player2, player3], new DefaultGameOpts);
	auto flow = new MahjongFlow(metagame, new NullNotificationService);
	assert(eventhandler.mahjongEvent.data.length == 2, "As two out of three players have a mahjong");
}

unittest
{
    import fluent.asserts;
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
    import mahjong.domain.player;
	import mahjong.engine.creation;
    import mahjong.engine.opts;
	auto eventhandler = new TestEventHandler;
	auto eventhandler2 = new TestEventHandler;
	auto player1 = new Player(eventhandler, 30_000);
	auto player2 = new Player(eventhandler2, 30_000);
    auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
    metagame.initializeRound;
	metagame.beginRound;
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀗🀗🀆🀆"d.convertToTiles;
	player1.hasDrawnTheirLastTile;
	flow = new MahjongFlow(metagame, new NullNotificationService);
	eventhandler.mahjongEvent.handle;
	eventhandler2.mahjongEvent.handle;
	flow.advanceIfDone;
    .flow.should.be.instanceOf!RoundStartFlow.because("a new round should start");
}

unittest
{
    import fluent.asserts;
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
    import mahjong.domain.player;
	import mahjong.engine.creation;
    import mahjong.engine.opts;
	class NoMoreGame : Metagame
	{
		this(Player[] players)
		{
			super(players, new DefaultGameOpts);
            initializeRound;
			beginRound;
            _isGameOver = true;
		}

        private bool _isGameOver;

		override bool isGameOver() 
		{
			return _isGameOver;
		}
	}

	auto eventhandler = new TestEventHandler;
	auto eventhandler2 = new TestEventHandler;
	auto player1 = new Player(eventhandler, 30_000);
	auto player2 = new Player(eventhandler2, 30_000);
    auto metagame = new NoMoreGame([player1, player2]);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀗🀗🀆🀆"d.convertToTiles;
	player1.hasDrawnTheirLastTile;
	flow = new MahjongFlow(metagame, new NullNotificationService);
	eventhandler.mahjongEvent.handle;
	eventhandler2.mahjongEvent.handle;
	flow.advanceIfDone;
    .flow.should.be.instanceOf!GameEndFlow;
}

