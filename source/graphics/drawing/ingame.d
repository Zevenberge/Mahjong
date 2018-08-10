module mahjong.graphics.drawing.ingame;

import std.algorithm.iteration;
import std.conv;
import std.experimental.logger;
import std.range;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.ingame;
import mahjong.domain.wrappers;
import mahjong.graphics.conv;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.openhand;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;

alias drawIngame = draw;
void draw(const Ingame ingame, const AmountOfPlayers amountOfPlayers,
    RenderTarget view)
{
    auto drawable = getDrawable(ingame, amountOfPlayers);
	drawable.draw(view);
}

void clearIngameCache()
{
	info("Clearing ingame cache");
	_ingameDrawables.clear;
	clearOpenHandCache;
	clearTileCache;
}

private IngameDrawable[UUID] _ingameDrawables;
private IngameDrawable getDrawable(const Ingame ingame,
    const AmountOfPlayers amountOfPlayers)
{
	if(ingame.id !in _ingameDrawables)
	{
		trace("Initialising new ingame drawable");
		auto drawable = new IngameDrawable(ingame, amountOfPlayers);
		_ingameDrawables[ingame.id] = drawable;
		return drawable;
	}
	return _ingameDrawables[ingame.id];
}

private class IngameDrawable
{
	size_t previousAmountOfDiscards;
	
	this(const Ingame game, const AmountOfPlayers amountOfPlayers)
	{
		_game = game;
        _amountOfPlayers = amountOfPlayers;
	}
	
	private const Ingame _game;
    private const AmountOfPlayers _amountOfPlayers;
	
	void draw(RenderTarget target)
	{
		_game.closedHand.drawClosedHand(target);
		_game.openHand.drawOpenHand(_game, _amountOfPlayers, target);
		drawDiscards(target);
	}

	private void drawDiscards(RenderTarget view)
	{
		auto amountOfDiscards = _game.discards.length;
		if(amountOfDiscards == previousAmountOfDiscards + 1)
		{
			// One additional tile was discarded.
			animateLastDiscard;
			previousAmountOfDiscards = amountOfDiscards;
		}
		else if(amountOfDiscards == previousAmountOfDiscards -1)
		{
			previousAmountOfDiscards = amountOfDiscards;
		}
		_game.discards.each!(t => t.drawTile(view));
	}

	private void animateLastDiscard()
	{
		trace("Starting the animation of the last discard");
		auto tile = _game.discards[$-1];
		auto coords = getNewCoords;
		tile.move(coords);
	}
	
	private FloatCoords getNewCoords()
	{
		auto tileSize = drawingOpts.tileSize;
		auto tileIndex = getDiscardIndex(_game.discards.length.to!int - 1);
		auto movement = calculatePositionInSquare(
						drawingOpts.amountOfDiscardsPerLine, 
						discardUndershoot,
						tileIndex, tileSize.toRect);
		auto position = styleOpts.center;
		return FloatCoords(position+movement, 0);
	}
}

private void placeDiscards(const Ingame ingame)
{
	foreach(number, tile; ingame.discards)
	{
		auto tileSize = tile.getGlobalBounds;
		auto tileIndex = getDiscardIndex(number.to!int);
		auto movement = calculatePositionInSquare(
						drawingOpts.amountOfDiscardsPerLine, 
						discardUndershoot,
						tileIndex, tileSize);
		auto position = styleOpts.center;
		tile.setCoords(FloatCoords(position+movement, 0));
	}
}

private Vector2i getDiscardIndex(int number)
{
	auto discardLines = drawingOpts.amountOfDiscardLines;
	auto discardsPerLine = drawingOpts.amountOfDiscardsPerLine;
	int x = 0, y = 0;
	if(number >= (discardLines-1)*discardsPerLine)
	{
		x = number - (discardLines-1)*discardsPerLine;
		y = discardLines - 1;
	}
	else
	{
		x = number % discardsPerLine;
		y = number/discardsPerLine;
	}
	return Vector2i(x,y);
}

deprecated Vector2f calculatePositionInSquare(const int amountOfTiles, const float undershootInTiles, const Vector2i tileIndex, const FloatRect sizeOfTile)
{ /*
     This function calculates the position of the nth tile with in the bottom player quadrant. This function assumes that the amountOfTiles tiles form a square with an undershoot in tiles. Please note that it is the responsibility of the caller to ensure that nthTile < amountOfTiles.
     Furthermore, this function assumes an unrotated tile. It returns the draw position of the tile with respect to the center of the board. Unrotated tiles will therefore be displaye next to each other.
  */
	float delta = (amountOfTiles - undershootInTiles)* sizeOfTile.width /2; // Distance from the center to the inner line of the square.
	auto movement = Vector2f(-delta, delta);
	movement.x += sizeOfTile.width * tileIndex.x;
	movement.y += tileIndex.y * sizeOfTile.height;
	return movement;
}





