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
	 Normal functions related to claiming tiles.
	 */
	private bool isOwn(const Tile tile)
	{
		return tile.origin == wind;
	}

	bool isPonnable(const Tile discard)
	{
		if(isOwn(discard)) return false;
		return closedHand.isPonnable(discard);
	}

	bool isKannable(const Tile discard)
	{
		if(isOwn(discard)) return false;
		return closedHand.isKannable(discard);
	}

	bool isRonnable(ref Tile discard)
	{
		if(isOwn(discard)) return false;
		return scanHand(closedHand.tiles ~ discard) && !isFuriten ;
	}

	/*
	 Functions related to the mahjong call.
	 */

	bool checkTenpai()
	{ /*
		   Check whether a player sits tempai. Add one of each tile to the hand to see whether it will be a mahjong hand.
		   */
		bool isTenpai = false;
		for(int type = Types.min; type <= Types.max; ++type)
		{
			for(int value = Numbers.min; value <= Numbers.max; ++value)
			{
				auto tile = new Tile(type, value);
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

	bool isMahjong()
	{
		return scanHand(closedHand.tiles);
	}

	private bool scanHand(Tile[] set)
	{
		return .scanHand(set, pons, chis);
		//FIXME: take into account yaku requirement.
	}

	private void discard(size_t discardedNr)
	{    
		takeOutTile(closedHand.tiles, discards, discardedNr);
		auto discard = discards[$-1];
		discard.origin = wind; // Sets the tile to be from the player who discarded it.
		discard.open;
		if( (!discard.isHonour) && (!discard.isTerminal) )
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
		foreach(tile; closedHand.tiles)
		{
			if(tile.isIdentical(discardedTile))
			{
				discard(i);
				return;
			}
			++i;
		}
		throw new TileNotFoundException(discardedTile);
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