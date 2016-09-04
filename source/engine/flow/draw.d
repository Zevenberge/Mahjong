module mahjong.engine.flow.draw;

import mahjong.domain;
import mahjong.engine.flow;

class DrawFlow : Flow
{
	this(Player player, Metagame metagame, Wall wall)
	{
		_player = player;
		this.metagame = metagame;
		_wall = wall;
	}
	
	private Player _player;
	private Wall _wall;
	
	override void advanceIfDone()
	{
		_player.drawTile(_wall);
		switchFlow(new TurnFlow(_player, metagame));
	}
}
///
unittest
{
	import std.stdio;
	import mahjong.domain.enums.tile;
	import mahjong.engine.opts;
	
	writeln("Testing draw flow.");
	gameOpts = new DefaultGameOpts ;
	
	auto player = new Player(new TestEventHandler);
	player.startGame(Winds.east);
	auto metagame = new Metagame([player]);
	auto wall = new Wall;
	wall.setUp;
	writeln("Setup finished.");
	auto wallLength = wall.length;
	// The flow of the game determines that it is time to draw.
	auto drawFlow = new DrawFlow(player, metagame, wall);
	switchFlow(drawFlow);
	flow.advanceIfDone;
	assert(wallLength - 1 == wall.length, "A tile should be taken from the wall.");
	assert(player.game.closedHand.length == 1, "The player should be given a tile.");
	assert(typeid(flow) == typeid(TurnFlow));
	writeln("Draw flow test succeeded.");
}