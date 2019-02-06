module mahjong.graphics.drawing.openhand;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.ingame;
import mahjong.domain.openhand;
import mahjong.domain.set;
import mahjong.domain.tile;
import mahjong.domain.wrappers;
import mahjong.engine.mahjong;
import mahjong.engine.opts;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.share.range;

alias drawOpenHand = draw;
void draw(const OpenHand hand, const Ingame ingame, 
    const AmountOfPlayers amountOfPlayers,
    RenderTarget view)
{
	hand.getOpenHandVisuals(ingame, amountOfPlayers).draw(view);
}

void clearOpenHandCache()
{
	_hands.clear;
	trace("Cleared open hand cache");
}

private:

OpenHandVisuals[UUID] _hands;

OpenHandVisuals getOpenHandVisuals(const OpenHand hand, const Ingame ingame, const AmountOfPlayers amountOfPlayers)
{
	if(hand.id !in _hands)
	{
		trace("Generating new open hand visual for ", hand.id);
		auto handVisuals = new OpenHandVisuals(hand, ingame, amountOfPlayers);
		_hands[hand.id] = handVisuals;
		return handVisuals;
	}
	return _hands[hand.id];
}

class OpenHandVisuals
{
	this(const OpenHand hand, const Ingame ingame, const AmountOfPlayers amountOfPlayers)
	{
		_hand = hand;
		_ingame = ingame;
        _amountOfPlayers = amountOfPlayers;
	}

	void draw(RenderTarget view)
	{
		updateIfNecessary;
		_sets.each!(s => s.draw(view));
	}

	private const OpenHand _hand;
	private const Ingame _ingame;
    private const AmountOfPlayers _amountOfPlayers;
	private SetVisual[] _sets;

	private void updateIfNecessary()
	{
		updateExistingSets;
		updateNewSet;
	}

	private void updateExistingSets()
	{
		foreach(i, set; _sets)
		{
			set.update(_hand.sets[i]);
		}
	}

	private void updateNewSet()
	{
		if(_sets.length != _hand.sets.length)
		{
			auto previousSet = _sets.empty ? null : _sets.back;
			_sets ~= new SetVisual(_hand.sets.back.tiles, previousSet, _ingame, _amountOfPlayers);
		}
	}
}

class SetVisual
{
	this(const(Tile)[] set, SetVisual previous, const Ingame ingame, const AmountOfPlayers amountOfPlayers)
	{
		_set = set;
        _amountOfPlayers = amountOfPlayers;
		placeSet(previous, ingame);
	}

	void draw(RenderTarget view)
	{
		_set.each!(t => t.drawTile(view));
	}

	void update(const(Set) set)
	{
		if(set.tiles.length == _set.length) return;
		placeAdditionalKanTile(set.tiles.back);
	}

    private const size_t _amountOfPlayers;
	private const(Tile)[] _set;

	private void placeSet(SetVisual previous, const Ingame ingame)
	{
		orderSet(ingame);
		auto rightBound = calculateInitialRightBounds(previous);
		foreach(tile; _set)
		{
			tile.display;
			rightBound = placeTileAndReturnItsLeftBound(tile, rightBound);
		}
		flipTilesfaceDownIfTheSetIsAClosedKan;
	}

	private void orderSet(const Ingame ingame)
	{
		if(isClosedKan) return;
		auto isKan = _set.length == 4;
		auto tileFromOtherPlayer = _set.first!(t => t.origin !is null);
		_set.remove!((a, b) => a == b)(tileFromOtherPlayer);
		auto differenceInWinds = (tileFromOtherPlayer.origin.wind - ingame.wind + _amountOfPlayers) 
			% _amountOfPlayers;
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

	private void placeAdditionalKanTile(const Tile tile)
	{
		_set ~= tile;
		tile.display;
		auto horizontalTile = _set.first!(t => t.origin !is null);
		auto coordsOfHorizontalTile = horizontalTile.getCoords;
		auto topLeft = Vector2f(coordsOfHorizontalTile.x,
			coordsOfHorizontalTile.y - drawingOpts.tileWidth);
		tile.move(FloatCoords(topLeft, 90));
	}

	private void flipTilesfaceDownIfTheSetIsAClosedKan()
	{
		if(!isClosedKan) return;
		_set[0].dontDisplay;
		_set[3].dontDisplay;
		assert(!_set.any!(t => t.isOpen));
	}

	private bool isClosedKan()
	{
		return _set.length == 4 && !_set.any!(t => t.origin !is null);
	}

	private FloatRect getGlobalBounds()
	{
		return calcGlobalBounds(_set);
	}
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	drawingOpts = new DefaultDrawingOpts;
	styleOpts = new DefaultStyleOpts;
	auto firstIngame = new Ingame(PlayerWinds.south);
	auto secondIngame = new Ingame(PlayerWinds.west);
	auto tiles = "🀡🀡🀡"d.convertToTiles;
	tiles[0].origin = secondIngame;
	firstIngame.openHand.addPon(tiles);
	draw(firstIngame.openHand, firstIngame, AmountOfPlayers(4), new RenderTexture);
	assert(_hands.length == 1, "One open hand visual should have been created");
	assert(_hands[firstIngame.openHand.id]._sets.length == 1, "The one open hand should have one set");
	assert(_hands[firstIngame.openHand.id]._sets[0]._set.length == 3, "The one set should have three tiles");
	clearOpenHandCache;
	clearTileCache;
}
unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	drawingOpts = new DefaultDrawingOpts;
	styleOpts = new DefaultStyleOpts;
	auto firstIngame = new Ingame(PlayerWinds.south);
	auto secondIngame = new Ingame(PlayerWinds.west);
	auto tiles = "🀡🀡🀡"d.convertToTiles;
	tiles[0].origin = secondIngame;
	firstIngame.openHand.addPon(tiles);
	draw(firstIngame.openHand, firstIngame, AmountOfPlayers(4),new RenderTexture);
	draw(firstIngame.openHand, firstIngame, AmountOfPlayers(4), new RenderTexture);
	// Drawing a second time should have no effect as nothing is changed.
	assert(_hands.length == 1, "One open hand visual should have been created");
	assert(_hands[firstIngame.openHand.id]._sets.length == 1, "The one open hand should have one set");
	assert(_hands[firstIngame.openHand.id]._sets[0]._set.length == 3, "The one set should have three tiles");
	clearOpenHandCache;
	clearTileCache;
}
unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	drawingOpts = new DefaultDrawingOpts;
	styleOpts = new DefaultStyleOpts;
	auto firstIngame = new Ingame(PlayerWinds.south);
	auto secondIngame = new Ingame(PlayerWinds.west);
	auto tiles = "🀡🀡🀡"d.convertToTiles;
	auto kanTile = "🀡"d.convertToTiles[0];
	tiles[0].origin = secondIngame;
	firstIngame.openHand.addPon(tiles);
	draw(firstIngame.openHand, firstIngame, AmountOfPlayers(2), new RenderTexture);
	firstIngame.openHand.promoteToKan(kanTile);
	draw(firstIngame.openHand, firstIngame, AmountOfPlayers(2), new RenderTexture);
	// Drawing a second time should update the set.
	assert(_hands.length == 1, "One open hand visual should have been created");
	assert(_hands[firstIngame.openHand.id]._sets.length == 1, "The one open hand should have one set");
	assert(_hands[firstIngame.openHand.id]._sets[0]._set.length == 4, "The one set should have four tiles");
	clearOpenHandCache;
	clearTileCache;
}

unittest
{
	import mahjong.domain.enums;
	import mahjong.engine.creation;
	drawingOpts = new DefaultDrawingOpts;
	styleOpts = new DefaultStyleOpts;
	auto firstIngame = new Ingame(PlayerWinds.south);
	auto tiles = "🀡🀡🀡🀡"d.convertToTiles;
	firstIngame.openHand.addKan(tiles);
	draw(firstIngame.openHand, firstIngame, AmountOfPlayers(4), new RenderTexture);
	assert(_hands.length == 1, "One open hand visual should have been created");
	assert(_hands[firstIngame.openHand.id]._sets.length == 1, "The one open hand should have one set");
	auto kan = _hands[firstIngame.openHand.id]._sets[0]._set;
	assert(kan.length == 4, "The one set should have four tiles");
	clearOpenHandCache;
	clearTileCache;
}