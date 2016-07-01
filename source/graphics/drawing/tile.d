module mahjong.graphics.drawing.tile;

import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.enums.tile;
import mahjong.domain.tile;
import mahjong.graphics.cache.texture;
import mahjong.graphics.conv;
import mahjong.graphics.coords;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;

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
	trace("Getting coords for tile");
	return getTileVisuals(tile).getCoords;
}

deprecated FloatRect getGlobalBounds(const Tile tile) 
{
	return  getTileVisuals(tile).getGlobalBounds;
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
	private FloatCoords _coords;
	
	void initialise(const Tile stone)
	{
		trace("Initialising tile visual for tile ", stone.id);
		loadTilesTexture;
		_sprite = new Sprite(tilesTexture);
		_sprite.textureRect = getTextureRect(stone);
		_sprite.pix2scale(tile.displayWidth);
		trace("Initialised tile visual for tile ", stone.id);
	}
	
	void setCoords(FloatCoords coords)
	{
		_coords = coords;
	}
	
	FloatCoords getCoords()
	{
		trace("Coords getter called");
		return _coords;
	}
	
	FloatRect getGlobalBounds()
	{
		_sprite.position = _coords.position;
		_sprite.rotation = _coords.rotation;
		return _sprite.getGlobalBounds;
	}
	
	void draw(const Tile tile, RenderTarget view)
	{
		Sprite sprite;
		if(tile.isOpen)
		{
			sprite = _sprite; 
		}
		else
		{
			sprite = getClosedSprite;
		}
		sprite.position = _coords.position;
		sprite.rotation = _coords.rotation;
		view.draw(sprite);
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

private Sprite getClosedSprite()
{
	if(_backSprite is null)
	{
		return initialiseNewBackSprite;
	}
	return _backSprite;
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
	_backSprite = new Sprite(tilesTexture);
	_backSprite.textureRect = getBackSpriteBounds;
	_backSprite.color = Color.Red;
	_backSprite.pix2scale(tile.displayWidth);
	return _backSprite;
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
private Sprite _backSprite;













