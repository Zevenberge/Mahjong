module mahjong.engine.flow.draw;

import mahjong.domain.player;
import mahjong.domain.wall;
import mahjong.engine.flow;

class DrawFlow : Flow
{
	this(Player player, Wall wall)
	{
		_player = player;
		_wall = wall;
	}
	
	private Player _player;
	private Wall _wall;
	
	override void checkProgress()
	{
		_player.drawTile(_wall);
		advance;
	}
	
	private void advance()
	{
		switchFlow(new TurnFlow(_player));
	}
}
///
unittest
{
	import std.stdio;
	import mahjong.domain.enums.tile;
	import mahjong.engine.opts.opts;
	import mahjong.engine.opts.defaultopts;
	
	writeln("Testing draw flow.");
	gameOpts = new DefaultGameOpts ;
	
	auto player = new Player;
	player.firstGame(Winds.east);
	auto wall = new Wall;
	wall.setUp;
	writeln("Setup finished.");
	auto wallLength = wall.length;
	// The flow of the game determines that it is time to draw.
	auto drawFlow = new DrawFlow(player, wall);
	switchFlow(drawFlow);
	flow.checkProgress;
	assert(wallLength - 1 == wall.length, "A tile should be taken from the wall.");
	assert(player.game.closedHand.length == 1, "The player should be given a tile.");
	assert(typeid(flow) == typeid(TurnFlow));
	writeln("Draw flow test succeeded.");
}