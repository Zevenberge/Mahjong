module mahjong.domain.wall;

import std.algorithm;
import std.array;
import std.conv;
import std.experimental.logger;
import std.random;

import mahjong.domain.creation;
import mahjong.domain.enums;
import mahjong.domain.opts;
import mahjong.domain.tile;

class Wall
{
    private const Opts _opts;
	private Tile[] _tiles;
	const(Tile)[] tiles() @property pure const
	{
		return _tiles;
	}

	this(const Opts opts) pure
	{
        debug trace("Constructing the wall");
        _opts = opts;
	}

	
	size_t length() @property pure const
	{
		return _tiles.length;
	}

	void dice()
	{
		debug info("Rolling the dice for the wall");
		diceToStartPoint();
		flipFirstDoraIndicator();
		debug info("Wall is ready to go.");
	}

	void setUp()
	{
		debug trace("Resetting the wall");
		initialise();
		debug trace("Initialized the wall");
		shuffle();
		debug trace("Shuffled the wall");
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
	private int calculateWallShift(int diceRoll) pure
	{
		auto plyrs = _opts.amountOfPlayers;
		int wallSide = (diceRoll-1)%plyrs;
		return ((plyrs - wallSide-1) % plyrs) * to!int(length)/plyrs;
	}
	private void splitWall(const int shift)
	{
		int _shift = (shift+to!int(length)) % cast(int)length;
		auto twall = this._tiles[_shift .. $] ~ this._tiles[0 .. _shift];
		this._tiles = twall;
	}
	
	protected void flipFirstDoraIndicator() pure
	{
		_tiles[$-5].open;
	}   
	
	protected void flipDoraIndicator() pure
	{
		auto indexOfLastOpenedDoraIndicator = _tiles.countUntil!(t => t.isOpen);
		_tiles[indexOfLastOpenedDoraIndicator-2].open;
	}

	const(Tile)[] doraIndicators() @property pure const
	{
		return _tiles.filter!(t => t.isOpen).array;
	}

	Tile drawTile() pure
	in(_tiles.length > 0, "No tiles to draw from the wall")
	{ 
		Tile drawnTile = _tiles[0];
		_tiles = _tiles[1 .. $];
		return drawnTile;
	}

    private ubyte _amountOfKans;
	Tile drawKanTile() pure
	in(_tiles.length > 0, "No tiles to draw from the wall")
	in(!isMaxAmountOfKansReached, "Exceeding max amount of kans")
	{ 
		flipDoraIndicator;
		return getKanTile;      
	}
	
	protected Tile getKanTile() pure
	{
        _amountOfKans++;
		Tile kanTile = _tiles[$-1];
		_tiles = _tiles[0 .. $-1];
		return kanTile;
	}

    bool canRiichiBeDeclared() @property pure const @nogc nothrow
    {
        return (_tiles.length - _opts.deadWallLength) > _opts.riichiBuffer;
    }

	bool isExhaustiveDraw() @property pure const @nogc nothrow
	{
		return _tiles.length <= _opts.deadWallLength;
	}

    bool isMaxAmountOfKansReached() @property pure const @nogc nothrow
    {
        return _amountOfKans == _opts.maxAmountOfKans;
    }
}

unittest
{
	auto wall = new Wall(new DefaultGameOpts);
	wall.setUp;
	wall.dice;
	assert(wall.doraIndicators.length == 1, "The wall should be initialised with one flipped dora indicator");
}

unittest
{
	import std.exception;
	import mahjong.domain.exceptions;
	import mahjong.domain.ingame;
	import mahjong.domain.player;
	import mahjong.domain.creation;
	auto wall = new Wall(new DefaultGameOpts);
	wall.setUp;
	wall.dice;
	auto initialWallLength = wall.length;
	auto lastTile = wall.tiles.back;
	auto player = new Player();
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀕🀕🀕"d.convertToTiles;
	auto kannableTile = "🀕"d.convertToTiles[0];
	kannableTile.isNotOwn;
	player.kan(kannableTile, wall);
	assert(player.game.closedHand.tiles.front == lastTile, "The last tile of the wall should have been drawn");
	assert(wall.length == initialWallLength - 1, "The wall should have decreased by 1");
	assert(wall.doraIndicators.length == 2, "An additional dora indicator should be flipped.");
}

unittest
{
    import fluent.asserts;
    class TwoKanOps : DefaultGameOpts
    {
        override int maxAmountOfKans() pure const
        {
            return 2;
        }
    }
    auto wall = new Wall(new TwoKanOps);
    wall.setUp;
    wall.dice;
    wall.drawKanTile;
    wall.isMaxAmountOfKansReached.should.equal(false);
    wall.drawKanTile;
    wall.isMaxAmountOfKansReached.should.equal(true);
}

class BambooWall : Wall
{
    this(const Opts opts) pure
    {
        super(opts);
    }

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
	import std.exception;
	import mahjong.domain.creation;
	import mahjong.domain.exceptions;
	import mahjong.domain.ingame;
	import mahjong.domain.player;
	auto wall = new BambooWall(new DefaultGameOpts);
	wall.setUp;
	wall.dice;
	auto initialWallLength = wall.length;
	auto firstTile = wall.tiles.front;
	auto player = new Player();
	player.startGame(PlayerWinds.east);
	player.game.closedHand.tiles = "🀕🀕🀕"d.convertToTiles;
	auto kannableTile = "🀕"d.convertToTiles[0];
	kannableTile.isNotOwn;
	player.kan(kannableTile, wall);
	assert(player.game.closedHand.tiles.front == firstTile, "The first tile of the wall should have been drawn");
	assert(wall.length == initialWallLength - 1, "The wall should have decreased by 1");
}

version(mahjong_test)
{
	class MockWall : Wall
	{
        this(bool isExhaustiveDraw)
        {
            _isExhaustiveDraw = isExhaustiveDraw;
            this(new Tile(Types.wind, Winds.north));
        }

		this(Tile tileToDraw)
		{
            super(new DefaultGameOpts);
			_tileToDraw = tileToDraw;
		}

        private bool _isExhaustiveDraw;
		private Tile _tileToDraw;

		override Tile drawTile() 
		{
			return _tileToDraw;
		}

		override Tile drawKanTile() 
		{
			return  _tileToDraw;
		}

        override bool isExhaustiveDraw() const 
        {
            return _isExhaustiveDraw;
        }

	}
}













