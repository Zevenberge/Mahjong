module mahjong.domain.wall;

import std.algorithm;
import std.conv;
import std.experimental.logger;
import std.random;
import std.uuid;

import mahjong.domain.enums;
import mahjong.domain.tile;
import mahjong.engine.creation;
import mahjong.engine.opts;

class Wall
{
	const UUID id;
	private Tile[] _tiles;
	const(Tile)[] tiles() @property
	{
		return _tiles;
	}

	private int amountOfKans = 0;

	this()
	{
		trace("Constructing the wall");
		id = randomUUID;
	}

	
	@property public size_t length()
	{
		return _tiles.length;
	}

	void dice()
	{
		info("Rolling the dice for the wall");
		diceToStartPoint();
		flipFirstDoraIndicator();
		info("Wall is ready to go.");
	}

	void setUp()
	{
		trace("Resetting the wall");
		this.amountOfKans = 0;
		initialise();
		trace("Initialized the wall");
		shuffle();
		trace("Shuffled the wall");
	}

	protected void initialise()
	{
		.setUpWall(_tiles);
	}

	private void shuffle()
	in
	{
		assert(length > 0);
	}
	body
	{
		for(int i = 0; i < 500; ++i)
		{
			ulong t1 = uniform(0, length);
			ulong t2 = uniform(0, length);
			swap(_tiles[t1],_tiles[t2]);
		}
	}

	protected void diceToStartPoint()
	{
		int result = rollDice(2);
		// Calculate which player is pointed to, and shift the split by a quarter of the wall times the player appointed.
		int split = calculateWallShift(result);
		// Start counting from the right and shift the wall back by two times (height of the wall) te result of the dice roll.
		split += 2 * result;
		splitWall(split);
	}
	
	private int rollDice(int amountOfDice)
	{
		int result = 0;
		for(int i = 0; i < amountOfDice; ++i)
		{
			result += uniform(0,6)+1;
		}
		return result;
	}
	private int calculateWallShift(int diceRoll)
	{
		auto plyrs = gameOpts.amountOfPlayers;
		int wallSide = (diceRoll-1)%plyrs;
		return ((plyrs - wallSide-1) % plyrs) * to!int(length)/plyrs;
	}
	private void splitWall(const int shift)
	{
		int _shift = (shift+to!int(length)) % cast(int)length;
		auto twall = this._tiles[_shift .. $] ~ this._tiles[0 .. _shift];
		this._tiles = twall;
	}
	
	protected void flipFirstDoraIndicator()
	{
		_tiles[$-5].open;
	}   
	
	protected void flipDoraIndicator()
	{
		auto indexOfLastOpenedDoraIndicator = _tiles.countUntil!(t => t.isOpen);
		_tiles[indexOfLastOpenedDoraIndicator-2].open;
	}

	Tile drawTile()
	{ 
		Tile drawnTile = _tiles[0];
		_tiles = _tiles[1 .. $];
		return drawnTile;
	}

	public Tile drawKanTile()
	{ 
		flipDoraIndicator;
		return getKanTile;      
	}
	
	protected Tile getKanTile()
	{
		Tile kanTile = _tiles[$-1];
		_tiles = _tiles[0 .. $-1];
		return kanTile;
	}

	bool isExhaustiveDraw()
	{
		return _tiles.length <= gameOpts.deadWallLength;
	}

}

unittest
{
	import std.array;
	import std.exception;
	import mahjong.domain.exceptions;
	import mahjong.domain.ingame;
	import mahjong.domain.player;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	gameOpts = new DefaultGameOpts;
	auto wall = new Wall;
	wall.setUp;
	wall.dice;
	auto initialWallLength = wall.length;
	auto lastTile = wall.tiles.back;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀕🀕🀕"d.convertToTiles;
	auto kannableTile = "🀕"d.convertToTiles[0];
	kannableTile.origin = new Ingame(1);
	player.kan(kannableTile, wall);
	assert(player.game.closedHand.tiles.front == lastTile, "The last tile of the wall should have been drawn");
	assert(wall.length == initialWallLength - 1, "The wall should have decreased by 1");
}

class BambooWall : Wall
{
	protected override void initialise()
	{
		for(int j = Numbers.min; j <= Numbers.max; ++j)
		{
			for(int i = 0; i < 4; ++i)
			{
				_tiles ~= new Tile(Types.bamboo, j);
				if(j == Numbers.five && i == 0)
					++_tiles[$-1].dora;
			}
		}
	}

	protected override void diceToStartPoint()
	{
		// Do nothing
	}
	
	protected override void flipFirstDoraIndicator()
	{
		// Do nothing
	}
	
	protected override void flipDoraIndicator()
	{
		// Do nothing
	}
	
	protected override Tile getKanTile()
	{
		return drawTile;
	}

}

unittest
{
	import std.array;
	import std.exception;
	import mahjong.domain.exceptions;
	import mahjong.domain.ingame;
	import mahjong.domain.player;
	import mahjong.engine.creation;
	import mahjong.engine.flow;
	gameOpts = new DefaultGameOpts;
	auto wall = new BambooWall;
	wall.setUp;
	wall.dice;
	auto initialWallLength = wall.length;
	auto firstTile = wall.tiles.front;
	auto player = new Player(new TestEventHandler);
	player.startGame(0);
	player.game.closedHand.tiles = "🀕🀕🀕"d.convertToTiles;
	auto kannableTile = "🀕"d.convertToTiles[0];
	kannableTile.origin = new Ingame(1);
	player.kan(kannableTile, wall);
	assert(player.game.closedHand.tiles.front == firstTile, "The first tile of the wall should have been drawn");
	assert(wall.length == initialWallLength - 1, "The wall should have decreased by 1");
}
class EightPlayerWall : Wall
{
	
}














