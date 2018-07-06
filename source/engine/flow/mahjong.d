module mahjong.engine.flow.mahjong;

import std.algorithm;
import std.array;
import std.conv;
import std.experimental.logger;
import mahjong.domain.enums;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.engine.mahjong;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class MahjongFlow : Flow
{
	this(Metagame game, INotificationService notificationService)
	{
		trace("Constructing mahjong flow");
		super(game, notificationService);
		auto data = game.constructMahjongData;
		notifyPlayers(data);
	}

	private void notifyPlayers(const(MahjongData)[] data)
	{
		foreach(player; _metagame.players)
		{
			auto event = new MahjongEvent(metagame, data);
			_events ~= event;
			player.eventHandler.handle(event);
		}
	}

	private MahjongEvent[] _events;

	override void advanceIfDone()
	{
		if(!_events.all!(e => e.isHandled)) return;
		_metagame.finishRound;
		mixin(gameOverSwitch);
		flow = new RoundStartFlow(_metagame, _notificationService);
	}
}

enum gameOverSwitch =
q{
	if(_metagame.isGameOver)
	{
		flow = new GameEndFlow(_metagame, _notificationService);
		return;
	}
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
	import mahjong.engine.creation;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d.convertToTiles;
	auto metagame = new Metagame([player1]);
	auto flow = new MahjongFlow(metagame, new NullNotificationService);
	assert(eventhandler.mahjongEvent !is null, "A mahjong event should have been distributed.");
	assert(eventhandler.mahjongEvent.data.empty, "No player has a mahjong, so the data should be empty.");
}
unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
	import mahjong.engine.creation;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto metagame = new Metagame([player1]);
	auto flow = new MahjongFlow(metagame, new NullNotificationService);
	assert(eventhandler.mahjongEvent.data.length == 1, "As the only player has a mahjong, one data should be added");
}
unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
	import mahjong.engine.creation;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto player2 = new Player(eventhandler);
	player2.game = new Ingame(PlayerWinds.south);
	player2.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d.convertToTiles;
	auto metagame = new Metagame([player1, player2]);
	auto flow = new MahjongFlow(metagame, new NullNotificationService);
	assert(eventhandler.mahjongEvent.data.length == 1, "As only one of two players has a mahjong, one data should be added");
	assert(eventhandler.mahjongEvent.data[0].player == player1, "The mahjong player is player 1");
}
unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
	import mahjong.engine.creation;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto player2 = new Player(eventhandler);
	player2.game = new Ingame(PlayerWinds.south);
	player2.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d.convertToTiles;
	auto player3 = new Player(eventhandler);
	player3.game = new Ingame(PlayerWinds.west);
	player3.game.closedHand.tiles = "🀃🀃🀃🀄🀄🀄🀚🀚🀚🀝🀝🀝🀡🀡"d.convertToTiles;
	auto metagame = new Metagame([player1, player2, player3]);
	auto flow = new MahjongFlow(metagame, new NullNotificationService);
	assert(eventhandler.mahjongEvent.data.length == 2, "As two out of three players have a mahjong");
}

unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
	import mahjong.engine.creation;
	import mahjong.test.utils;
	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d.convertToTiles;
	auto metagame = new Metagame([player1]);
	flow = new MahjongFlow(metagame, new NullNotificationService);
	eventhandler.mahjongEvent.handle;
	flow.advanceIfDone;
	assert(flow.isOfType!RoundStartFlow, "After a mahjong, a new round should start");
}

unittest
{
	import mahjong.domain.closedhand;
	import mahjong.domain.enums;
	import mahjong.domain.ingame;
	import mahjong.engine.creation;
	import mahjong.test.utils;
	class NoMoreGame : Metagame
	{
		this(Player[] players)
		{
			super(players);
		}

		override bool isGameOver() 
		{
			return true;
		}
	}

	auto eventhandler = new TestEventHandler;
	auto player1 = new Player(eventhandler);
	player1.game = new Ingame(PlayerWinds.east);
	player1.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d.convertToTiles;
	auto metagame = new NoMoreGame([player1]);
	flow = new MahjongFlow(metagame, new NullNotificationService);
	eventhandler.mahjongEvent.handle;
	flow.advanceIfDone;
	assert(flow.isOfType!GameEndFlow, "After a mahjong, a new round should start");
}
struct MahjongData
{
	const(Player) player;
	const(MahjongResult) result;
	bool isWinningPlayerEast() @property pure const
	{
		return player.isEast;
	}
	size_t calculateMiniPoints(PlayerWinds leadingWind) pure const
	{
		if(result.isSevenPairs) return 25;
		auto miniPointsFromSets = result.calculateMiniPoints(player.wind.to!PlayerWinds, leadingWind);
		auto miniPointsFromWinning = isTsumo ? 30 : 20;
		return miniPointsFromSets + miniPointsFromWinning;
	}

	bool isTsumo() @property pure const
	{
		return player.lastTile.isOwn;
	}
}

unittest
{
	import mahjong.domain.ingame;
	import mahjong.domain.tile;
	import mahjong.domain.wall;
	import mahjong.engine.creation;
	auto wall = new MockWall(new Tile(Types.ball, Numbers.six));
	auto player = new Player(new TestEventHandler);
	player.game = new Ingame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀟"d.convertToTiles;
	player.drawTile(wall);
	auto mahjongResult = player.scanHandForMahjong;
	auto data = MahjongData(player, mahjongResult);
	assert(data.isTsumo, "Being mahjong after drawing a tile is a tsumo"); 
	assert(data.calculateMiniPoints(PlayerWinds.south) == 40, "Pon of honours + pair of dragons + tsumo = 40");
}

unittest
{
	import mahjong.domain.ingame;
	import mahjong.domain.tile;
	import mahjong.engine.creation;
	auto player = new Player(new TestEventHandler);
	player.game = new Ingame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀖🀖🀗"d.convertToTiles;
	auto tile = new Tile(Types.bamboo, Numbers.eight);
	tile.origin = new Ingame(PlayerWinds.south);
	player.ron(tile);
	auto mahjongResult = player.scanHandForMahjong;
	auto data = MahjongData(player, mahjongResult);
	assert(!data.isTsumo, "Being mahjong after ron is not a tsumo"); 
	assert(data.calculateMiniPoints(PlayerWinds.south) == 25, "Seven pairs is always 25, regardless of what pairs");
}

unittest
{
	import mahjong.domain.ingame;
	import mahjong.domain.tile;
	import mahjong.domain.wall;
	import mahjong.engine.creation;
	auto wall = new MockWall(new Tile(Types.ball, Numbers.six));
	auto player = new Player(new TestEventHandler);
	player.game = new Ingame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀀🀀🀀🀓🀔🀕🀅🀅🀜🀝🀝🀞🀟"d.convertToTiles;
	auto tile = new Tile(Types.wind, Winds.east);
	tile.origin = new Ingame(PlayerWinds.south);
	player.kan(tile, wall);
	auto mahjongResult = player.scanHandForMahjong;
	auto data = MahjongData(player, mahjongResult);
	assert(data.isTsumo, "Being mahjong after kan is a tsumo"); 
	assert(data.calculateMiniPoints(PlayerWinds.south) == 48, "Open kan of honours + pair of dragons + tsumo = 48");
}

