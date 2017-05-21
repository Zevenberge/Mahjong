module mahjong.domain.ingame;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.uuid;
import mahjong.domain;
import mahjong.domain.enums.tile;
import mahjong.domain.exceptions;
import mahjong.engine.chi;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;
import mahjong.engine.sort;

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
	private bool isOwn(const Tile tile) pure const
	{
		return tile.origin == wind;
	}

	private bool isContainedInDiscards(const Tile tile) pure const
	{
		return !discards.any!(t => tile.hasEqualValue(t));
	}

	bool isChiable(const Tile discard) pure const
	{
		if(isOwn(discard)) return false;
		return closedHand.isChiable(discard);
	}

	void chi(Tile discard, ChiCandidate otherTiles)
	{
		if(!isChiable(discard) || !otherTiles.isChi(discard)) 
		{
			throw new IllegalClaimException(discard, "Chi not allowed");
		}
		auto chiTiles = closedHand.removeChiTiles(otherTiles) ~ discard;
		openHand.addChi(chiTiles);
	}

	bool isPonnable(const Tile discard) pure
	{
		if(isOwn(discard)) return false;
		return closedHand.isPonnable(discard);
	}

	void pon(Tile discard)
	{
		if(!isPonnable(discard)) throw new IllegalClaimException(discard, "Pon not allowed");
		auto ponTiles = closedHand.removePonTiles(discard) ~ discard;
		openHand.addPon(ponTiles);
	}

	bool isKannable(const Tile discard) pure
	{
		if(isOwn(discard)) return false;
		return closedHand.isKannable(discard);
	}

	void kan(Tile discard)
	{
		if(!isKannable(discard)) throw new IllegalClaimException(discard, "Kan not allowed");
		auto kanTiles = closedHand.removeKanTiles(discard) ~ discard;
		openHand.addKan(kanTiles);
	}

	bool isRonnable(const Tile discard) pure const
	{
		if(isContainedInDiscards(discard)) return false;
		return scanHandForMahjong(closedHand.tiles ~ discard, openHand.amountOfPons).isMahjong
			&& !isFuriten ;
	}

	/*
	 Functions related to the mahjong call.
	 */

	bool checkTenpai()
	{ /*
		   Check whether a player sits tempai. Add one of each tile to the hand to see whether it will be a mahjong hand.
		   */
		for(int type = Types.min; type <= Types.max; ++type)
		{
			for(int value = Numbers.min; value <= Numbers.max; ++value)
			{
				auto tile = new Tile(type, value);
				Tile[] temphand = closedHand.tiles ~ tile;
				if(.scanHandForMahjong(temphand, openHand.amountOfPons).isMahjong)
				{
					this.isTenpai = true;
					return true;
				}

			}
		}
		this.isTenpai = false;
		return false;
	}

	bool isFuriten() @property pure const
	{
		foreach(tile; discards)
		{
			if(.scanHandForMahjong(closedHand.tiles ~ tile, openHand.amountOfPons).isMahjong)
			{
				return true;
			}
		}
		return false;
	}

	bool isMahjong()
	{
		return scanHandForMahjong(closedHand, openHand).isMahjong;
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
	
	void drawTile(Wall wall)
	{
		closedHand.drawTile(wall);
		lastTile = closedHand.getLastTile;
	}

}