module mahjong.graphics.drawing.tile;

import std.algorithm;
import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.enums;
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
	getTileVisuals(tile).draw(view);
}

void display(const Tile tile)
{
	getTileVisuals(tile).display;
}

void dontDisplay(const Tile tile)
{
	getTileVisuals(tile).dontDisplay;
}

void clearTileCache()
{
	_tiles.length = 0;
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

FloatRect getGlobalBounds(const Tile tile) 
{
	return  getTileVisuals(tile).getGlobalBounds;
}

void move(const Tile tile, FloatCoords finalCoords, int duration = 15)
{
	auto sprite = getFrontSprite(tile);
	auto animation = new MovementAnimation(sprite, finalCoords, 15);
	animation.object = tile;
	addUniqueAnimation(animation);
}

void rotate(const Tile tile)
{
    auto visual = tile.getTileVisuals;
    visual.rotate;
}

bool isRotated(const Tile tile) @property
{
    auto visual = tile.getTileVisuals;
    return visual.isRotated;
}

private Sprite getFrontSprite(const Tile tile)
{
	return getTileVisuals(tile)._sprite;
}

private final class TileVisuals
{
	private Sprite _sprite;
	private Sprite _backSprite;
	private const Tile _tile;

	this(const Tile tile)
	{
		_tile = tile;
		initialise();
	}
	
	void initialise()
	{
		loadTilesTexture;
		_sprite = new Sprite(tilesTexture);
		_sprite.textureRect = getTextureRect(_tile);
		_sprite.setSize(tile.displayWidth);
		_backSprite = initialiseNewBackSprite;
	}
	
	mixin delegateCoords!([_sprite.stringof, _backSprite.stringof]);
	
	FloatRect getGlobalBounds()
	{
		return _sprite.getGlobalBounds;
	}

	void draw(RenderTarget view)
	{
		updateCoords;
		if(shouldDrawFrontSprite())
		{
			view.draw(_sprite); 
		}
		else
		{
			view.draw(_backSprite);
		}
	}

	private bool shouldDrawFrontSprite() pure const @nogc nothrow
	{
		return _tile.isOpen || _shouldBeDisplayed;
	}

	private bool _shouldBeDisplayed;
	void display() pure @nogc nothrow
	{
		_shouldBeDisplayed = true;
	}

	void dontDisplay() pure @nogc nothrow
	{
		_shouldBeDisplayed = false;
	}

    private bool _isRotated;
    bool isRotated() pure const @property @nogc nothrow
    {
        return _isRotated;
    }

    void rotate() pure @nogc nothrow
    {
        _isRotated = true;
    }
	
	private void updateCoords()
	{
		// A tile is manipulated by its front sprite,
		// E.g. by animations.
		// Propagate the change to the back sprite.
		auto spriteCoords = _sprite.getFloatCoords;
		if(_coords != spriteCoords)
		{
			trace("Front sprite updated.");
			_coords = spriteCoords;
			_backSprite.setFloatCoords(_coords);
			return;
		}
	}
}

private TileVisuals getTileVisuals(const Tile tile)
{
	auto visuals = _tiles.filter!(t => t._tile is tile);
	if(visuals.empty)
	{
		auto tileVisuals = new TileVisuals(tile);
		_tiles ~= tileVisuals;
		return tileVisuals;
	}
	else
	{
		return visuals.front;
	}
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
	backSprite.setSize(tile.displayWidth);
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

private TileVisuals[] _tiles;













