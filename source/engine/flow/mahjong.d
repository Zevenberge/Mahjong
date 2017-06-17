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

class MahjongFlow : Flow
{
	this(Metagame game)
	{
		trace("Constructing mahjong flow");
		super(game);
		auto data = constructMahjongData;
		notifyPlayers(data);
	}

	private const(MahjongData)[] constructMahjongData()
	{
		return metagame.players.map!((player){
				auto mahjongResult = scanHandForMahjong(player);
				return MahjongData(player, mahjongResult);
			}).filter!(data => data.result.isMahjong).array;
	}

	private void notifyPlayers(const(MahjongData)[] data)
	{
		foreach(player; metagame.players)
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
		flow = new RoundStartFlow(metagame);
	}
}

class MahjongEvent
{
	this(Metagame metagame,
		const(MahjongData)[] data)
	{
		_data = data;
		this.metagame = metagame;
	}

	Metagame metagame;

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

struct MahjongData
{
	const(Player) player;
	const(MahjongResult) result;
	bool isWinningPlayerEast() @property pure const
	{
		return player.wind == PlayerWinds.east;
	}
	size_t calculateMiniPoints(PlayerWinds leadingWind) pure const
	{
		if(result.isSevenPairs) return 25;
		auto miniPointsFromSets = result.calculateMiniPoints(player.wind.to!PlayerWinds, leadingWind);
		auto miniPointsFromWinning = isTsumo ? 30 : 20;
		return miniPointsFromSets + miniPointsFromWinning;
	}

	private bool isTsumo() @property pure const
	{
		return player.lastTile.isOwn;
	}
	// More e.g. yaku rating.
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
	auto flow = new MahjongFlow(metagame);
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
	auto flow = new MahjongFlow(metagame);
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
	auto flow = new MahjongFlow(metagame);
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
	auto flow = new MahjongFlow(metagame);
	assert(eventhandler.mahjongEvent.data.length == 2, "As two out of three players have a mahjong");
}