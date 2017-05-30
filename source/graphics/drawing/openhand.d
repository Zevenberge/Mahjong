module mahjong.graphics.drawing.openhand;

import std.algorithm.iteration;
import std.array;
import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.ingame;
import mahjong.domain.openhand;
import mahjong.domain.tile;
import mahjong.engine.enums.game;
import mahjong.engine.opts;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.share.range;

alias drawOpenHand = draw;
void draw(OpenHand hand, Ingame ingame, RenderTarget view)
{
	hand.getOpenHandVisuals(ingame).draw(view);
}

void clearOpenHandCache()
{
	_hands.clear;
	trace("Cleared open hand cache");
}

private:

OpenHandVisuals[UUID] _hands;

OpenHandVisuals getOpenHandVisuals(OpenHand hand, Ingame ingame)
{
	if(hand.id !in _hands)
	{
		trace("Generating new open hand visual for ", hand.id);
		auto handVisuals = new OpenHandVisuals(hand, ingame);
		_hands[hand.id] = handVisuals;
		return handVisuals;
	}
	return _hands[hand.id];
}

class OpenHandVisuals
{
	this(OpenHand hand, Ingame ingame)
	{
		_hand = hand;
		_ingame = ingame;
	}

	void draw(RenderTarget view)
	{
		updateIfNecessary;
		_sets.each!(s => s.draw(view));
	}

	private OpenHand _hand;
	private Ingame _ingame;
	private SetVisual[] _sets;

	private void updateIfNecessary()
	{
		if(_sets.length != _hand.sets.length)
		{
			auto previousSet = _sets.empty ? null : _sets.back;
			_sets ~= new SetVisual(_hand.sets.back.tiles, previousSet, _ingame);
		}
		// TODO: when kakan is implemented: also check set length
	}
}

class SetVisual
{
	this(const(Tile)[] set, SetVisual previous, Ingame ingame)
	{
		_set = set;
		placeSet(previous, ingame);
	}

	void draw(RenderTarget view)
	{
		_set.each!(t => t.drawTile(view));
	}

	private const(Tile)[] _set;

	private void placeSet(SetVisual previous, Ingame ingame)
	{
		orderSet(ingame);
		auto rightBound = calculateInitialRightBounds(previous);
		foreach(tile; _set)
		{
			rightBound = placeTileAndReturnItsLeftBound(tile, rightBound);
		}
	}

	private void orderSet(Ingame ingame)
	{
		auto isKan = _set.length == 4;
		auto tileFromOtherPlayer = _set.first!(t => t.origin !is null);
		_set.remove!((a, b) => a == b)(tileFromOtherPlayer);
		auto differenceInWinds = (tileFromOtherPlayer.origin.wind - ingame.wind + gameOpts.amountOfPlayers) 
			% gameOpts.amountOfPlayers;
		auto location = differenceInWinds - 1;
		info("Location is ", location);
		if(isKan && location != 0) location++; // Move the tilted tile one space to the left.
		_set = _set.insertAt(tileFromOtherPlayer, location);
	}

	private float calculateInitialRightBounds(SetVisual previous)
	{
		if(previous is null)
		{
			return styleOpts.gameScreenSize.y - drawingOpts.iconSize - drawingOpts.iconSpacing;
		}
		else
		{
			return previous.getGlobalBounds.left;
		}
	}

	private float placeTileAndReturnItsLeftBound(const Tile tile, float rightBound)
	{
		return tile.origin is null ?
			placeTileVertically(tile, rightBound) :
			placeTileHorizontally(tile, rightBound);
	}

	private float placeTileVertically(const Tile tile, float rightBound)
	{
		auto topLeft = Vector2f(rightBound - drawingOpts.tileWidth,
			styleOpts.gameScreenSize.y - drawingOpts.iconSize);
		tile.move(FloatCoords(topLeft, 0));
		return topLeft.x;
	}

	private float placeTileHorizontally(const Tile tile, float rightBound)
	{
		auto size = drawingOpts.tileSize;
		auto topLeft = Vector2f(rightBound,
			styleOpts.gameScreenSize.y - drawingOpts.iconSize + size.y - size.x);
		tile.move(FloatCoords(topLeft, 90));
		return rightBound - size.y;
	}

	private FloatRect getGlobalBounds()
	{
		return calcGlobalBounds(_set);
	}
}