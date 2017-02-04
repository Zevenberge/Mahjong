module mahjong.domain.ingame;

import std.algorithm.iteration;
import std.array;
import std.experimental.logger;
import std.uuid;
import mahjong.domain;
import mahjong.domain.enums.tile;
import mahjong.domain.exceptions;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;

class Ingame
{ 
	UUID id;
	// Ingame variables.
	int wind = -1; // What wind the player has. Initialise it with a value of -1 to allow easy assert(ingame.wind >= 0).
	ClosedHand closedHand; // The closed hand that can be changed. The discards are from here.
	OpenHand openHand; // The open pons/chis/kans 
	Tile[]  discards; // All of the personal discards.
	private Tile lastTile;  // The last tile, to determine whether or not this is a tsumo or a ron.
	bool isNagashiMangan = true;
	bool isRiichi = false;
	bool isDoubleRiichi = false;
	bool isFirstTurn = true;
	bool isTenpai = false;
	int pons=0; // Amount of open pons.
	int chis=0; // Amount of open chis.

	this(int wind)
	{
		this.wind = wind;
		closedHand = new ClosedHand;
		openHand = new OpenHand;
		id = randomUUID;
	}

	int getWind()
	{
		return wind;
	}

	
	/*
	 Normal dibsing functions.
	 */

	bool isPonnable(const ref Tile discard)
	{
		int i=0;
		foreach(tile; closedHand.tiles)
		{
			if(tile.hasEqualValue(discard))
			{
				if((i+1) < closedHand.tiles.length)
				{
					return closedHand.tiles[i+1].hasEqualValue(discard);
				}
			}
			++i;  
		}
		return false;
	}

	/*
	 Functions related to the mahjong call.
	 */

	bool checkTenpai()
	{ /*
		   Check whether a player sits tempai. Add one of each tile to the hand to see whether it will be a mahjong hand.
		   */
		bool isTenpai = false;
		auto tile = new Tile;
		for(int t = Types.min; t <= Types.max; ++t)
		{
			tile.type = t;
			for(int i = Numbers.min; i <= Numbers.max; ++i)
			{
				tile.value = i;
				Tile[] temphand = closedHand.tiles ~ tile;
				if(.scanHand(temphand, chis, pons))
				{
					isTenpai = true;
				}

			}
		}
		this.isTenpai = isTenpai;
		return isTenpai;
	}

	bool isFuriten()
	{
		foreach(tile; discards)
		{
			if(.scanHand(closedHand.tiles ~ tile, pons, chis))
			{
				return true;
			}
		}
		return false;
	}

	bool isRonnable(ref Tile discard)
	{
		return scanHand(closedHand.tiles ~ discard) && !isFuriten ;
	}

	bool isMahjong()
	{
		return scanHand(closedHand.tiles);
	}

	private bool scanHand(Tile[] set)
	{
		return .scanHand(set, pons, chis);
		//FIXME: take into account yaku requirement.
	}

	/*
	 Discard things you no longer need.
	 */
	void discard(UUID discardId)
	{
		size_t index;
		foreach(i, t; closedHand.tiles)
		{
			if(t.id == discardId)
			{
				index = i;
				break;
			}
		}
		discard(index);
	}

	void discard(ulong discardedNr)
	{    
		takeOutTile(closedHand.tiles, discards, discardedNr);
		discards[$-1].origin = wind; // Sets the tile to be from the player who discarded it.
		discards[$-1].open;
		if( (!discards[$-1].isHonour) && (!discards[$-1].isTerminal) )
		{
			if(isNagashiMangan)
			{
				info(cast(PlayerWinds)wind, " has lost Nagashi Mangan!");
			}
			isNagashiMangan = false;
		}
	}
	void discard(Tile discardedTile)
	{
		ulong i = 0;
		bool found = false;
		foreach(tile; closedHand.tiles)
		{
			if(tile.isIdentical(discardedTile))
			{
				found = true;
				discard(i);
				break;
			}
			++i;
		}
		if(!found)
		{
			throw new TileNotFoundException(discardedTile);
		}
	}
	ref Tile getLastDiscard()
	{
		return discards[$-1];
	}
	ref Tile getLastTile()
	{
		return lastTile;
	}

	void closeHand()
	{
		closedHand.closeHand;
	}
	
	void showHand()
	{
		closedHand.showHand;
	}
	
	void drawTile(ref Wall wall)
	{
		closedHand.drawTile(wall);
		lastTile = closedHand.getLastTile;
	}

}