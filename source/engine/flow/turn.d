module mahjong.engine.flow.turn;

import std.experimental.logger;
import std.uuid;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine.flow;

class TurnFlow : Flow
{
	this(Player player, Metagame meta)
	{
		_player = player;
		_meta = meta;
		_event = new TurnEvent(this, meta, player);
		_player.delegator.handle(_event);
	}
	
	override void advanceIfDone()
	{
		if(_event.isHandled)
		{
			assert(_flow !is null, "When the event is handled, the flow should not be null");
			advance();
		}
	}

	private: 
		TurnEvent _event;
		Player _player;
		Metagame _meta;
		Flow _flow;
	
		void advance()
		{
			switchFlow(_flow);
		}
		
		void discard(Tile tile)
		{
			_player.discard(tile);
			_flow = new RonFlow(tile, _meta);
		}

		void claimTsumo()
		{
			info("Tsumo claimed by ", _player.name);
			_meta.tsumo(_player);
			_flow = new MahjongFlow;
		}
}

class TurnEvent
{
	this(TurnFlow flow, Metagame metagame, Player player)
	{
		_flow = flow;
		this.player = player;
		this.metagame = metagame;
	}	
	private TurnFlow _flow;
	
	private bool isHandled = false;
	
	Player player;
	Metagame metagame;
	
	void discard(Tile tile)
	in
	{
		assert(!isHandled, "The event should not be handled twice.");
	}
	body
	{
		isHandled = true;
		_flow.discard(tile);
	}

	void claimTsumo()
	in
	{
		assert(!isHandled, "The event should not be handled twice.");
	}
	body
	{
		isHandled = true;
		_flow.claimTsumo;
	}
}



