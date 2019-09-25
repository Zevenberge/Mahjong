module mahjong.engine.flow.mahjong;

import std.algorithm;
import std.array;
import std.conv;
import std.experimental.logger;
import mahjong.domain.enums;
import mahjong.domain.mahjong;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class MahjongFlow : WaitForEveryPlayer!MahjongEvent
{
	this(Metagame game, INotificationService notificationService, Engine engine)
	{
		trace("Constructing mahjong flow");
		_mahjongData = game.constructMahjongData;
		super(game, notificationService, engine);
		trace("Finished constructing mahjong flow");
	}

	private const(MahjongData[]) _mahjongData;

	protected override MahjongEvent createEvent()
	{
		return new MahjongEvent(_metagame, _mahjongData);
	}

	protected override void advance(Engine engine)
	{
		_metagame.finishRound;
		mixin(switchToNextRoundOrGameOver);

	}
}

enum switchToNextRoundOrGameOver = q{
	if(_metagame.isGameOver)
	{
		engine.switchFlow(new GameEndFlow(_metagame, _notificationService, engine));
		return;
	}
	engine.switchFlow(new RoundStartFlow(_metagame, _notificationService, engine));
};

final class MahjongEvent
{
	import mahjong.engine.flow.traits : SimpleEvent;

	this(const Metagame metagame, const(MahjongData)[] data)
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

	mixin SimpleEvent!();
}

unittest
{
	import mahjong.domain.opts;
	import mahjong.domain.player;

	auto player1 = new Player("🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d);
	auto metagame = new Metagame([player1], new DefaultGameOpts);
	auto engine = new Engine(metagame);
	auto eventhandler = engine.getTestEventHandler(player1);
	auto flow = new MahjongFlow(metagame, new NullNotificationService, engine);
	assert(eventhandler.mahjongEvent.data.length == 1,
			"As the only player has a mahjong, one data should be added");
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.domain.opts;
	import mahjong.domain.player;

	auto player1 = new Player("🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d, PlayerWinds.east);
	auto player2 = new Player("🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d, PlayerWinds.south);
	auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
	auto engine = new Engine(metagame);
	auto eventhandler = engine.getTestEventHandler(player1);
	auto flow = new MahjongFlow(metagame, new NullNotificationService, engine);
	assert(eventhandler.mahjongEvent.data.length == 1,
			"As only one of two players has a mahjong, one data should be added");
	assert(eventhandler.mahjongEvent.data[0].player == player1, "The mahjong player is player 1");
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.domain.opts;
	import mahjong.domain.player;

	auto player1 = new Player("🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d, PlayerWinds.east);
	auto player2 = new Player("🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d, PlayerWinds.south);
	auto player3 = new Player("🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d, PlayerWinds.west);
	auto metagame = new Metagame([player1, player2, player3], new DefaultGameOpts);
	auto engine = new Engine(metagame);
	auto eventhandler = engine.getTestEventHandler(player1);
	auto flow = new MahjongFlow(metagame, new NullNotificationService, engine);
	assert(eventhandler.mahjongEvent.data.length == 2, "As two out of three players have a mahjong");
}

unittest
{
	import fluent.asserts;
	import mahjong.domain.closedhand;
	import mahjong.domain.creation;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
	import mahjong.domain.opts;
	import mahjong.domain.player;

	auto player1 = new Player();
	auto player2 = new Player();
	auto metagame = new Metagame([player1, player2], new DefaultGameOpts);
	metagame.initializeRound;
	metagame.beginRound;
	auto engine = new Engine(metagame);
	auto eventhandler = engine.getTestEventHandler(player1);
	auto eventhandler2 = engine.getTestEventHandler(player2);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles
		= "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀗🀗🀆🀆"d.convertToTiles;
	player1.hasDrawnTheirLastTile;
	auto flow = new MahjongFlow(metagame, new NullNotificationService, engine);
	engine.switchFlow(flow);
	eventhandler.mahjongEvent.handle;
	eventhandler2.mahjongEvent.handle;
	engine.advanceIfDone;
	engine.flow.should.be.instanceOf!RoundStartFlow.because("a new round should start");
}

unittest
{
	import fluent.asserts;
	import mahjong.domain.closedhand;
	import mahjong.domain.creation;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
	import mahjong.domain.opts;
	import mahjong.domain.player;

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

		override bool isGameOver() const pure nothrow @nogc
		{
			return _isGameOver;
		}
	}

	auto player1 = new Player();
	auto player2 = new Player();
	auto metagame = new NoMoreGame([player1, player2]);
	auto engine = new Engine(metagame);
	auto eventhandler = engine.getTestEventHandler(player1);
	auto eventhandler2 = engine.getTestEventHandler(player2);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles
		= "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀗🀗🀆🀆"d.convertToTiles;
	player1.hasDrawnTheirLastTile;
	auto flow = new MahjongFlow(metagame, new NullNotificationService, engine);
	engine.switchFlow(flow);
	eventhandler.mahjongEvent.handle;
	eventhandler2.mahjongEvent.handle;
	engine.advanceIfDone;
	engine.flow.should.be.instanceOf!GameEndFlow;
}

@("A mahjong event is a simple event")
unittest
{
	import fluent.asserts;
    import mahjong.engine.flow.traits;
	isSimpleEvent!MahjongEvent.should.equal(true);
}