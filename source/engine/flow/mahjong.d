module mahjong.engine.flow.mahjong;

import std.algorithm;
import std.array;
import std.experimental.logger;
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
	// More e.g. yaku rating.
}