module mahjong.engine.flow.draw;

import mahjong.domain;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.engine.notifications;

final class DrawFlow : Flow
{
	this(Player player, Metagame metagame, Wall wall, 
		INotificationService notificationService)
	{
		super(metagame, notificationService);
		_player = player;
		_wall = wall;
	}
	
	private Player _player;
	private Wall _wall;
	
	override void advanceIfDone(Engine engine)
	{
		_player.drawTile(_wall);
		engine.switchFlow(new TurnFlow(_player, _metagame, _notificationService, engine));
	}
}

unittest
{
    import fluent.asserts;
	import mahjong.domain.enums;
	import mahjong.domain.opts;

	auto player = new Player;
	player.startGame(PlayerWinds.east);
	auto metagame = new Metagame([player], new DefaultGameOpts);
	auto wall = new Wall(new DefaultGameOpts);
	wall.setUp;
	auto wallLength = wall.length;
	auto drawFlow = new DrawFlow(player, metagame, wall, new NullNotificationService);
	auto engine = new Engine(metagame);
	engine.switchFlow(drawFlow);
	engine.advanceIfDone;
    wall.length.should.equal(wallLength - 1).because("a tile is drawn");
    player.closedHand.length.should.equal(1).because("they drew a tile");
    engine.flow.should.be.instanceOf!TurnFlow;
}