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
		_event = new TurnEvent(this, meta, player, player.lastTile);
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

		void promoteToKan(Tile tile)
		{
			_player.promoteToKan(tile, metagame.wall);
			_flow = new TurnFlow(_player, metagame);
		}

		void declareClosedKan(Tile tile)
		{
			_player.declareClosedKan(tile, metagame.wall);
			_flow = new TurnFlow(_player, metagame);
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

	void promoteToKan(Tile tile)
	in
	{
		assert(!isHandled, "The event should not be handled twice.");
	}
	body
	{
		isHandled = true;
		_flow.promoteToKan(tile);
	}

	void declareClosedKan(Tile tile)
	in
	{
		assert(!isHandled, "The event should not be handled twice.");
	}
	body
	{
		isHandled = true;
		_flow.declareClosedKan(tile);
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
	import mahjong.domain.enums;
	import mahjong.engine.opts;
	import mahjong.test.utils;

	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(PlayerWinds.east);
	auto metagame = new Metagame([player]);
	auto tile = new Tile(Types.dragon, Dragons.green);
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	assert(.flow.isOfType!TurnFlow, "TurnFlow should be set as flow");
	flow.advanceIfDone;
	assert(.flow.isOfType!TurnFlow, "As the player is not ready, the flow should not have advanced");
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.domain.tile;
	import mahjong.domain.wall;
	import mahjong.engine.opts;
	import mahjong.test.utils;

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

	gameOpts = new DefaultGameOpts;

	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(PlayerWinds.east);
	auto metagame = new Metagame([player]);
	auto tile = new Tile(Types.dragon, Dragons.green);
	auto wall = new MockWall(tile);
	player.drawTile(wall);
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	flow._event.discard(tile);
	flow.advanceIfDone;
	assert(.flow.isOfType!ClaimFlow, "A tile is discarded, therefore the flow should move over to a ron.");
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	import mahjong.engine.mahjong;
	import mahjong.engine.opts;
	import mahjong.test.utils;

	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(PlayerWinds.east);
	auto metagame = new Metagame([player]);
	auto tile = new Tile(Types.dragon, Dragons.green);
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	player.game.closedHand.tiles = "🀐🀐🀐🀐🀑🀒🀓🀔🀕🀖🀗🀘🀘🀘"d.convertToTiles;
	flow._event.claimTsumo;
	flow.advanceIfDone;
	assert(.flow.isOfType!MahjongFlow, "A tsumo is claimed, therefore the flow should move over to the defeault mahjong flow.");
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	import mahjong.engine.opts;
	import mahjong.test.utils;
	gameOpts = new DefaultGameOpts;
	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(PlayerWinds.east);
	auto metagame = new Metagame([player]);
	metagame.nextRound;
	metagame.beginRound;
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	player.closedHand.tiles = "🀐🀐🀐🀐🀘🀘"d.convertToTiles;
	auto kanTile = player.closedHand.tiles[0];
	flow._event.declareClosedKan(kanTile);
	flow.advanceIfDone;
	assert(.flow.isOfType!TurnFlow, "After declaring a closed kan, the flow should be at the turn again");
	assert(.flow !is flow, "The flow should be another instance");
	assert(player.openHand.amountOfKans == 1, "The player should have one kan");
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	import mahjong.engine.opts;
	import mahjong.test.utils;
	gameOpts = new DefaultGameOpts;
	auto eventHandler = new TestEventHandler;
	auto player = new Player(eventHandler);
	player.startGame(PlayerWinds.east);
	auto metagame = new Metagame([player]);
	metagame.nextRound;
	metagame.beginRound;
	auto flow = new TurnFlow(player, metagame);
	switchFlow(flow);
	player.closedHand.tiles = "🀐🀘🀘"d.convertToTiles;
	player.openHand.addPon("🀐🀐🀐"d.convertToTiles);
	auto kanTile = player.closedHand.tiles[0];
	flow._event.promoteToKan(kanTile);
	flow.advanceIfDone;
	assert(.flow.isOfType!TurnFlow, "After declaring a closed kan, the flow should be at the turn again");
	assert(.flow !is flow, "The flow should be another instance");
	assert(player.openHand.amountOfKans == 1, "The player should have one kan");
}