module mahjong.domain.wall;

import std.algorithm.mutation;
import std.conv;
import std.experimental.logger;
import std.random;

import mahjong.domain.enums.game;
import mahjong.domain.enums.tile;
import mahjong.domain.enums.wall;
import mahjong.domain.tile;
import mahjong.engine.mahjong;
import mahjong.engine.opts.opts;


class Wall
{
	Tile[] tiles;
   private int amountOfKans = 0;

   this()
   {
   		trace("Constructing the wall");
   }


   @property public size_t length()
   {
     return tiles.length;
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
		set_up_wall(tiles);
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
			swap(tiles[t1],tiles[t2]);
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
	
	protected final int rollDice(int amountOfDice)
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
      auto twall = this.tiles[_shift .. $] ~ this.tiles[0 .. _shift];
      this.tiles = twall;
   }
   
	protected void flipFirstDoraIndicator()
	{
		tiles[$-5].open;
	}   
	
	protected void flipDoraIndicator()
	{
		// TODO
	}

/*
   In-game functions.
*/
   public Tile drawTile()
   { // Not to be confused with the graphical draw functions.
      Tile drawnTile = tiles[0];
      tiles = tiles[1 .. $];
      return drawnTile;
   }
   public Tile drawKanTile()
   { // Not to be confused with the graphical draw functions nor the normal draw. In addition, this function also flips the dora indictor.
      flipDoraIndicator;
      return getKanTile;      
   }
   
	protected Tile getKanTile()
	{
		Tile kanTile = tiles[$-1];
		tiles = tiles[0 .. $-1];
		return kanTile;
	}

	public bool isExhaustiveDraw()
	{
		return tiles.length <= gameOpts.deadWallLength;
	}

   public bool isAbortiveDraw()
   { // FIXME: Take into account that this is invalid in the ultrarare case in which all of the kans belong to a single player.
      return amountOfKans == 4;
   }

	public bool canStillKan()
	{
		return tiles.length > deadWallLength + kanBuffer && amountOfKans < 4;
	}
}

class BambooWall : Wall
{
	protected override void initialise()
	{
		for(int j = Numbers.min; j <= Numbers.max; ++j)
		{
			for(int i = 0; i < 4; ++i)
			{
				tiles ~= new Tile(Types.bamboo, j);
				if(j == Numbers.five && i == 0)
					++tiles[$-1].dora;
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
	
	public override bool canStillKan()
	{
		return tiles.length > 0;
	}
}

class EightPlayerWall : Wall
{
	
}














