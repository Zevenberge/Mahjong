module mahjong.graphics.drawing.tile;

import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.enums.tile;
import mahjong.domain.tile;
import mahjong.graphics.cache.texture;
import mahjong.graphics.coords;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.graphics;

alias drawTile = draw;
void draw(const Tile tile, RenderTarget view)
{
	Sprite sprite;
	if(tile.isOpen)
	{
		sprite = getOpenSprite(tile);
	}
	else
	{
		sprite = getClosedSprite;
	}
	auto coords = getCoords(tile);
	sprite.position = coords.vector;
	sprite.rotation = coords.rotation;
	view.draw(sprite);
}

void clearTileCache()
{
	_sprites.clear;
	_coords.clear;
	trace("Cleared tiles cache");
}

void setCoords(const Tile tile, FloatCoords coords)
{
	_coords[tile.id] = coords;
}

FloatCoords getCoords(const Tile tile)
{
	if(tile.id !in _coords)
	{
		return FloatCoords.init;
	}
	return _coords[tile.id];
}

deprecated FloatRect getGlobalBounds(const Tile tile) 
{
	if(tile.id !in _sprites) return FloatRect();
	return _sprites[tile.id].getGlobalBounds;
}
deprecated void setPosition(Tile tile, Vector2f pos)
{
	_sprites[tile.id].position(pos);
}


private Sprite getOpenSprite(const Tile tile)
{
	if(tile.id !in _sprites)
	{
		return initialiseNewSprite(tile);
	}
	return _sprites[tile.id];
}

private Sprite getClosedSprite()
{
	if(_backSprite is null)
	{
		return initialiseNewBackSprite;
	}
	return _backSprite;
}

private Sprite initialiseNewSprite(const Tile stone)
{
	loadTilesTexture;
	auto sprite = new Sprite(tilesTexture);
	sprite.textureRect = getTextureRect(stone);
	sprite.pix2scale(tile.displayWidth);
	_sprites[stone.id] = sprite;
	return sprite;
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
	if(tilesTexture is null)
	{
		tilesTexture.loadFromFile(tilesFile);
	}
}

private FloatCoords[UUID] _coords;
private Sprite[UUID] _sprites;
private Sprite _backSprite;













