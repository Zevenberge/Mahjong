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
		super(meta);
		_event = new TurnEvent(this, meta, player, player.getLastTile);
		_player.eventHandler.handle(_event);
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
		Flow _flow;

		void advance()
		{
			switchFlow(_flow);
		}
		
		void discard(Tile tile)
		{
			_player.discard(tile);
			_flow = new ClaimFlow(tile, metagame);
		}

		void claimTsumo()
		{
			info("Tsumo claimed by ", _player.name);
			metagame.tsumo(_player);
			_flow = new MahjongFlow(metagame);
		}
}

class TurnEvent
{
	this(TurnFlow flow, Metagame metagame, Player player, Tile drawnTile)
	{
		_flow = flow;
		this.player = player;
		this.metagame = metagame;
		this.drawnTile = drawnTile;
	}	
	private TurnFlow _flow;
	
	private bool isHandled = false;
	
	Player player;
	Metagame metagame;
	Tile drawnTile;
	
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

unittest
{
	import std.stdio;
	import mahjong.engine.opts;
	import mahjong.test.utils;

	writeln("Testing flow of turn when nothing happened.");
	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(0);
	auto metagame = new Metagame([player]);
	auto tile = new Tile(0,0);
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	assert(.flow.isOfType!TurnFlow, "TurnFlow should be set as flow");
	writeln("Testing whether the flow advances when it should not");
	flow.advanceIfDone;
	assert(.flow.isOfType!TurnFlow, "As the player is not ready, the flow should not have advanced");
	writeln("Idle turn flow test succeeded");
}

unittest
{
	import std.stdio;
	import mahjong.engine.opts;
	import mahjong.test.utils;
	import mahjong.domain.tile;
	import mahjong.domain.wall;

	class MockWall : Wall
	{
		this(Tile tileToDraw)
		{
			_tileToDraw = tileToDraw;
		}
		private Tile _tileToDraw;
		override Tile drawTile()
		{
			return _tileToDraw;
		}
	}

	writeln("Testing flow of turn when discarding.");
	gameOpts = new DefaultGameOpts;

	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(0);
	auto metagame = new Metagame([player]);
	auto tile = new Tile(0,0);
	auto wall = new MockWall(tile);
	player.drawTile(wall);
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	flow._event.discard(tile);
	writeln("Testing whether the flow advances when it should");
	flow.advanceIfDone;
	assert(.flow.isOfType!ClaimFlow, "A tile is discarded, therefore the flow should move over to a ron.");
	writeln("Turn to Ron flow test succeeded.");
}

unittest
{
	import std.stdio;
	import mahjong.engine.creation;
	import mahjong.engine.mahjong;
	import mahjong.engine.opts;
	import mahjong.test.utils;
	writeln("Testing flow of turn when claiming tsumo.");

	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(0);
	auto metagame = new Metagame([player]);
	auto tile = new Tile(0, 0);
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	player.game.closedHand.tiles = "🀐🀐🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘"d.convertToTiles;
	flow._event.claimTsumo;
	flow.advanceIfDone;
	assert(.flow.isOfType!MahjongFlow, "A tsumo is claimed, therefore the flow should move over to the defeault mahjong flow.");
	writeln("Turn to Mahjong flow test succeeded.");
}
