module mahjong.graphics.drawing.ingame;

import std.algorithm;
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
import mahjong.graphics.drawing.wall;
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

@("Drawing a game without open tiles should succeed")
unittest
{
	import std.typecons : BlackHole;
	import mahjong.domain.enums : PlayerWinds;
	scope(exit) clearIngameCache;
	auto ingame = new Ingame(PlayerWinds.east, "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀌🀗🀗"d);
	auto renderMock = new BlackHole!RenderTarget;
	auto amountOfPlayers = AmountOfPlayers(4);
	draw(ingame, amountOfPlayers, renderMock);
	// Implicit assert
}

@("Drawing a game with open tiles should succeed")
unittest
{
	import std.typecons : BlackHole;
	import mahjong.domain.enums : PlayerWinds, Types, Winds;
	import mahjong.domain.tile : Tile;
	scope(exit) clearIngameCache;
	auto ingame = new Ingame(PlayerWinds.east, "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀗🀗"d);
	auto tileToClaim = new Tile(Types.wind, Winds.south);
	tileToClaim.isNotOwn;
	ingame.pon(tileToClaim);
	auto renderMock = new BlackHole!RenderTarget;
	auto amountOfPlayers = AmountOfPlayers(4);
	draw(ingame, amountOfPlayers, renderMock);
	// Implicit assert
}

@("Draw a discard")
unittest
{
	import std.typecons : BlackHole;
	import mahjong.domain.enums : PlayerWinds, Types, Winds;
	import mahjong.domain.tile : Tile;
	scope(exit) clearIngameCache;
	auto ingame = new Ingame(PlayerWinds.east, "🀡🀡🀁🀁🀕🀕🀚🀚🀌🀌🀌🀗🀗"d);
	ingame.discard(ingame.closedHand.tiles[0]);
	auto renderMock = new BlackHole!RenderTarget;
	auto amountOfPlayers = AmountOfPlayers(4);
	draw(ingame, amountOfPlayers, renderMock);
	// Implicit assert
}

void clearIngameCache()
{
	info("Clearing ingame cache");
	_ingameDrawables.clear;
    clearWall;
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
		immutable amountOfDiscards = _game.discards.length;
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
		auto position = calculateOriginalCoordinates(tileIndex, tileSize.y);
		return correctForRiichi(position, tileSize);
	}

	private Vector2f calculateOriginalCoordinates(Vector2i tileIndex, float tileHeight)
	{
		immutable topLeft = calculatePositionForTheFirstDiscard();
		immutable yPosition = topLeft.y + tileIndex.y * tileHeight;
		if(tileIndex.x == 0)
		{
			return Vector2f(topLeft.x, yPosition);
		}
		else
		{
			immutable previousTile = _game.discards[$-2].getGlobalBounds;
			immutable leftBounds = previousTile.left + previousTile.width;
			return Vector2f(leftBounds, yPosition);
		}
	}

    private FloatCoords correctForRiichi(Vector2f originalCoords, Vector2f tileSize)
    {
        if(_game.isRiichi && !_game.discards.any!(tile => tile.isRotated))
		{
			_game.discards[$-1].rotate;
			return FloatCoords(
				originalCoords.x,
				originalCoords.y + tileSize.y, 
				-90);
		}
		return FloatCoords(originalCoords, 0);
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

Vector2f calculatePositionForTheFirstDiscard()
{
	return styleOpts.center + 
		calculateOffsetFromCenterInASquare(
			drawingOpts.amountOfDiscardsPerLine, 
			discardUndershoot);
}

Vector2f calculateOffsetFromCenterInASquare(const int amountOfTiles, const float undershootInTiles)
{
	immutable tileWidth = drawingOpts.tileWidth;
	immutable delta = (amountOfTiles - undershootInTiles) * tileWidth /2;
	return Vector2f(-delta, delta);
}

deprecated Vector2f calculatePositionInSquare(const int amountOfTiles, const float undershootInTiles, const Vector2i tileIndex, const FloatRect sizeOfTile)
{ /*
     This function calculates the position of the nth tile with in the bottom player quadrant. This function assumes that the amountOfTiles tiles form a square with an undershoot in tiles. Please note that it is the responsibility of the caller to ensure that nthTile < amountOfTiles.
     Furthermore, this function assumes an unrotated tile. It returns the draw position of the tile with respect to the center of the board. Unrotated tiles will therefore be displaye next to each other.
  */
	auto movement = calculateOffsetFromCenterInASquare(amountOfTiles, undershootInTiles);
	movement.x += sizeOfTile.width * tileIndex.x;
	movement.y += tileIndex.y * sizeOfTile.height;
	return movement;
}





