module mahjong.graphics.drawing.tile;

import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.enums.tile;
import mahjong.domain.tile;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.movement;
import mahjong.graphics.conv;
import mahjong.graphics.cache.texture;
import mahjong.graphics.conv;
import mahjong.graphics.coords;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;
import mahjong.graphics.meta;

alias drawTile = draw;
void draw(const Tile tile, RenderTarget view)
{
	getTileVisuals(tile).draw(tile, view);
}

void clearTileCache()
{
	_tiles.clear;
	trace("Cleared tiles cache");
}

void setCoords(const Tile tile, FloatCoords coords)
{
	getTileVisuals(tile).setCoords(coords);
}

FloatCoords getCoords(const Tile tile)
{
	return getTileVisuals(tile).getCoords;
}

Sprite getFrontSprite(const Tile tile)
{
	return getTileVisuals(tile)._sprite;
}

FloatRect getGlobalBounds(const Tile tile) 
{
	return  getTileVisuals(tile).getGlobalBounds;
}
FloatRect getLocalBounds(const Tile tile)
{
	return getTileVisuals(tile).getLocalBounds;
}

void move(const Tile tile, FloatCoords finalCoords)
{
	auto sprite = getFrontSprite(tile);
	auto animation = new MovementAnimation(sprite, finalCoords, 15);
	animation.objectId = tile.id;
	addUniqueAnimation(animation);
}

deprecated void setPosition(Tile tile, Vector2f pos)
{
	trace("Setting the position of the tile");
	auto coords = getCoords(tile);
	trace("Retreived the old coordinates");
	coords.x = pos.x;
	coords.y = pos.y;
	setCoords(tile, coords);
	trace("Set the new coords.");
}

private class TileVisuals
{
	private Sprite _sprite;
	private Sprite _backSprite;
	
	void initialise(const Tile stone)
	{
		trace("Initialising tile visual for tile ", stone.id);
		loadTilesTexture;
		_sprite = new Sprite(tilesTexture);
		_sprite.textureRect = getTextureRect(stone);
		_sprite.pix2scale(tile.displayWidth);
		_backSprite = initialiseNewBackSprite;
		trace("Initialised tile visual for tile ", stone.id);
	}
	
	mixin delegateCoords!([_sprite.stringof, _backSprite.stringof]);
	
	FloatRect getGlobalBounds()
	{
		return _sprite.getGlobalBounds;
	}
	
	FloatRect getLocalBounds()
	{
		return _sprite.getLocalBounds;
	}
	
	void draw(const Tile tile, RenderTarget view)
	{
		updateCoords;
		if(tile.isOpen)
		{
			view.draw(_sprite); 
		}
		else
		{
			view.draw(_backSprite);
		}
	}
	
	private void updateCoords()
	{
		auto spriteCoords = _sprite.getFloatCoords;
		if(_coords != spriteCoords)
		{
			trace("Front sprite updated.");
			_coords = spriteCoords;
			_backSprite.setFloatCoords(_coords);
			return;
		}
		auto backSpriteCoords = _backSprite.getFloatCoords;
		if(_coords != backSpriteCoords)
		{
			trace("Back sprite updated");
			_coords = backSpriteCoords;
			_sprite.setFloatCoords(_coords);
			return;
		}
	}
}

private TileVisuals getTileVisuals(const Tile tile)
{
	if(tile.id !in _tiles)
	{
		trace("Generating new tiles visual for \n", tile.id);
		auto tileVisuals = new TileVisuals;
		tileVisuals.initialise(tile);
		_tiles[tile.id] = tileVisuals;
		return tileVisuals;
	}
	return _tiles[tile.id];
}

private IntRect getTextureRect(const Tile stone)
{
	IntRect bounds;
	bounds.width = tile.width;
	bounds.height = tile.height;
	if(stone.isHonour) 
	{
		bounds.top = tile.y0;
		if(stone.type == Types.season)
		{
			 bounds.left = tile.x0 + (stone.value - Seasons.min) * tile.dx;
		}
		if(stone.type == Types.wind)
		{
			 bounds.left = tile.x0 + (stone.value - Winds.min + (Seasons.max - Seasons.min + 1)) * tile.dx;
		}
		if(stone.type == Types.dragon)
		{
			 bounds.left = tile.x0 + (stone.value - Dragons.min + (Seasons.max - Seasons.min + 1 + Winds.max - Winds.min + 1)) * tile.dx;
		}
	}
	else // We have a series.
	{
		bounds.top  = tile.y0 + (stone.type - Types.character + 1) * tile.dy;
		bounds.left = tile.x0 + (stone.value - Numbers.min + 1) * tile.dx;
	}
	return bounds;
}

private Sprite initialiseNewBackSprite()
{
	loadTilesTexture;
	auto backSprite = new Sprite(tilesTexture);
	backSprite.textureRect = getBackSpriteBounds;
	backSprite.color = Color.Red;
	backSprite.pix2scale(tile.displayWidth);
	return backSprite;
}
private IntRect getBackSpriteBounds()
{
	return IntRect(0, 100, tile.width, tile.height);
}

private void loadTilesTexture()
{
	trace("Retreiving tiles texture");
	if(tilesTexture is null)
	{
		info("Loading tiles texture into cache");
		tilesTexture = new Texture;
		tilesTexture.loadFromFile(tilesFile);
	}
}

private TileVisuals[UUID] _tiles;













