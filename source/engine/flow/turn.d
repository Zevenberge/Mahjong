module mahjong.engine.flow.turn;

import std.experimental.logger;
import std.uuid;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine.flow;
import mahjong.engine.notifications;

class TurnFlow : Flow
{
	this(Player player, Metagame meta, INotificationService notificationService)
	{
		_player = player;
		super(meta, notificationService);
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
		
		void discard(const Tile tile)
		{
			auto discard = _player.discard(tile);
			_flow = new ClaimFlow(discard, _metagame, _notificationService);
		}

		void promoteToKan(const Tile tile)
		{
			_player.promoteToKan(tile, _metagame.wall);
			_notificationService.notify(Notification.Kan, _player);
			_flow = new TurnFlow(_player, _metagame, _notificationService);
		}

		void declareClosedKan(const Tile tile)
		{
			_player.declareClosedKan(tile, _metagame.wall);
			_notificationService.notify(Notification.Kan, _player);
			_flow = new TurnFlow(_player, _metagame, _notificationService);
		}

		void claimTsumo()
		{
			info("Tsumo claimed by ", _player.name);
			_metagame.tsumo(_player);
			_notificationService.notify(Notification.Tsumo, _player);
			_flow = new MahjongFlow(_metagame, _notificationService);
		}
}

class TurnEvent
{
	this(TurnFlow flow, const Metagame metagame, const Player player, const Tile drawnTile)
	{
		_flow = flow;
		this.player = player;
		this.metagame = metagame;
		this.drawnTile = drawnTile;
	}	
	private TurnFlow _flow;
	
	private bool isHandled = false;
	
	const Player player;
	const Metagame metagame;
	const Tile drawnTile;
	
	void discard(const Tile tile)
	in
	{
		assert(!isHandled, "The event should not be handled twice.");
	}
	body
	{
		isHandled = true;
		_flow.discard(tile);
	}

	void promoteToKan(const Tile tile)
	in
	{
		assert(!isHandled, "The event should not be handled twice.");
	}
	body
	{
		isHandled = true;
		_flow.promoteToKan(tile);
	}

	void declareClosedKan(const Tile tile)
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
	auto flow = new TurnFlow(player, metagame, new NullNotificationService);
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
	auto flow = new TurnFlow(player, metagame, new NullNotificationService);
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
	auto flow = new TurnFlow(player, metagame, new NullNotificationService);
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
	metagame.initializeRound;
	metagame.beginRound;
	auto flow = new TurnFlow(player, metagame, new NullNotificationService);
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
	metagame.initializeRound;
	metagame.beginRound;
	auto flow = new TurnFlow(player, metagame, new NullNotificationService);
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