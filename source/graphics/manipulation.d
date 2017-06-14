module mahjong.graphics.manipulation;

import dsfml.graphics;
import dsfml.window;
import std.algorithm.comparison;
import std.conv;
import std.experimental.logger;
import std.file;
import std.format;
import std.math;
import std.range;

import mahjong.domain.enums;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.engine.ai;
import mahjong.engine.mahjong;
import mahjong.engine.opts;
import mahjong.engine.yaku;
import mahjong.graphics.cache.font;
import mahjong.graphics.conv;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.menu;
import mahjong.graphics.opts;
import mahjong.graphics.traits;

void load(ref Texture texture, ref Sprite sprite, string texturefile,
         uint x0 = 0, uint y0 = 0, uint size_x = 0, uint size_y = 0)
{
  if(size_x * size_y > 0)
  {
    loadTexture(texture, texturefile, x0, y0, size_x, size_y);
  }
  else
  {
    loadTexture(texture, texturefile);
  }
  texture.setSmooth(true);
  sprite.setTexture(texture);
}

bool loadTexture ( ref Texture texture, string texturefile,
         uint x0 = 0, uint y0 = 0, uint size_x = 0, uint size_y = 0)
{
      if(!texture.loadFromFile(texturefile, IntRect(x0, y0, size_x, size_y))) // If the size is specified, load only that partition.
      {
        error("File ", texturefile, " not found or out of bounds. Swapping in default texture.");
        texture.loadFromFile(defaultTexture);
        return false;
      }
  return true;
}

bool load(T) (ref T texture, string texturefile) 
{
  if(!texture.loadFromFile(texturefile))
  {
     error("File ", texturefile, " not found.");
     return false;
  }
  return true;
}
alias loadFont = load!Font;
alias loadTexture = load!Texture;
alias loadImage = load!Image;

void load(ref Texture texture)
{
   load(texture, defaultTexture);
}

void alignLeft(T) (T transformable, const FloatRect box)
	if(hasGlobalBounds!T && hasFloatPosition!T)
{
	transformable.position = Vector2f(box.left, box.top);
	center!(CenterDirection.Vertical)(transformable, box);
}

unittest
{
	auto rect = new RectangleShape(Vector2f(100, 50));
	auto bounds = FloatRect(200, 300, 500, 500);
	rect.alignLeft(bounds);
	assert(rect.position == Vector2f(200, 525), "The rectangle is not left-aligned properly");
}

void alignRight(T)(T transformable, const FloatRect box) 
	if(hasGlobalBounds!T && hasFloatPosition!T)
{
	auto size = transformable.getGlobalBounds;
	transformable.position = Vector2f(box.left + box.width - size.width, box.top);
	center!(CenterDirection.Vertical)(transformable, box);
}

unittest
{
	auto rect = new RectangleShape(Vector2f(100, 50));
	auto bounds = FloatRect(200, 300, 500, 500);
	rect.alignRight(bounds);
	assert(rect.position == Vector2f(600, 525), "The rectangle is not right-aligned properly");
}

void alignTopLeft(T) (T sprite, const FloatRect box)
{
  sprite.position = Vector2f(box.left, box.top);
}

void center(CenterDirection direction, T)(T sprite, const FloatRect rect) 
	if(hasGlobalBounds!T && hasFloatPosition!T)
{
	auto x0 = rect.left;
	auto h0 = rect.top;
	auto w = rect.width;
	auto h = rect.height;
	
	auto size = sprite.getGlobalBounds;
	auto pos = sprite.position;
	static if(direction != CenterDirection.Vertical)
	{
		pos.x = x0 + (w - size.width)/2.;
	}
	static if(direction != CenterDirection.Horizontal)
	{
		pos.y = h0 + (h - size.height)/2.;
	}
	sprite.position = pos;
}

void alignBottom(Sprite sprite, FloatRect box)
{
  auto size = sprite.getGlobalBounds();
  sprite.position = Vector2f(box.left, (box.top + box.height - size.height));
  trace("The top left corner is (", sprite.position.x, ",", sprite.position.y, ").");
  center!(CenterDirection.Horizontal)(sprite, 
  	FloatRect(box.left, box.top, box.width, box.height));
  trace("The top left corner is (", sprite.position.x, ",", sprite.position.y, ").");
}

void setTitle(Text title, string text)
{
  /*
    Have a function that takes care of a uniform style for all title fields.
  */
  with(title)
  {
  	setFont(titleFont);
  	setString(text);
  	setCharacterSize(48);
  	setColor(Color.Black);
  	position = Vector2f(200,20);
  }
  auto size = styleOpts.gameScreenSize;
  title.center!(CenterDirection.Horizontal)(FloatRect(0, 0, size.x, size.y));
}


void changeOpacity(ref ubyte[] opacities, const size_t position)
{
    /*
      Change the opacity of background images for a more or less fluid transition.
    */
	for(int opt = 0; opt < opacities.length;++opt)
	{
		if(opt == position)
		{
			opacities[opt] = min(opacities[opt]+10, 255).to!ubyte;
		}
		else
		{
			opacities[opt] = max(opacities[opt]-10, 0).to!ubyte;
		}
	}
}

void moveToPlayer(ref Vector2f location, const Vector2f movement, const int playLoc)
{
   float[2] loc = [location.x, location.y];
   float[2] mov = [movement.x, movement.y];
   moveToPlayer(loc,mov,playLoc);
   location = Vector2f(loc[0],loc[1]);
}
void moveToPlayer(ref float[2] location, const float[2] movement, const int playLoc)
{
trace("Movement is [", movement[0], ",", movement[1],"]" );
   float theta = 2 * PI - PI/2 * playLoc;

   location[0] += cos(theta) * movement[0] - sin(theta) * movement[1];
   location[1] += sin(theta) * movement[0] + cos(theta) * movement[1];
}

void rotateToPlayer(ref float rotation, const int playLoc)
{
   rotation = 0;
   addRotateToPlayer(rotation, playLoc);
}
void rotateToPlayer(ref Sprite sprite, const int playLoc)
{
   float rotation = sprite.rotation;
   rotateToPlayer(rotation, playLoc);
   sprite.rotation = rotation;
}
void rotateToPlayer(const Tile tile, const int playLoc)
{
	trace("Rotating tile ", tile.id," to player");
	auto coords = tile.getCoords;
	trace("Obtained the coords of tile ", tile.id);
	trace("Is drawing opts null? ", drawingOpts is null);
	coords.rotation = playLoc * drawingOpts.rotationPerPlayer;
	tile.setCoords(coords);
}

void addRotateToPlayer(ref float rotation, const int playLoc)
{
   rotation += (360 - 90 * playLoc) % 360;
}
void addRotateToPlayer(ref Sprite sprite, const int playLoc)
{
   float rotation = sprite.rotation;
   addRotateToPlayer(rotation, playLoc);
   sprite.rotation = rotation;
}
void addRotateToPlayer(const Tile tile, const int playLoc)
{
	auto coords = tile.getCoords;
	trace("Obtained the coords of tile ", tile.id);
	trace("Is drawing opts set? ", drawingOpts is null);
	coords.rotation += playLoc * drawingOpts.rotationPerPlayer;
	tile.setCoords(coords);
}

FloatRect calcGlobalBounds(T) (T opts)
{
    /*
      Get the rectangular global bounds of a given system.
    */
    FloatRect bounds;
    if(opts.length == 0)
    {
      bounds.top = 0;
      bounds.left = 0;
      bounds.height = 0;
      bounds.width = 0;
      return bounds;
    }
    bounds.top = float.max;
    bounds.left = float.max;
    bounds.height = 0;
    bounds.width = 0;
    foreach(opt; opts)
    {
       auto localBounds = opt.getGlobalBounds; // Nice naming, eh?
       if(localBounds.left < bounds.left)
       {
          bounds.left = localBounds.left;
       }
       if(localBounds.top < bounds.top)
       {
          bounds.top = localBounds.top;
       }
    }
    foreach(opt; opts)
    {
       auto localBounds = opt.getGlobalBounds; // Nice naming, eh?
       if((localBounds.left + localBounds.width - bounds.left) > bounds.width)
       {
          bounds.width = localBounds.left + localBounds.width - bounds.left;
       }
       if((localBounds.top + localBounds.height - bounds.top) > bounds.height)
       {
          bounds.height = localBounds.top + localBounds.height - bounds.top;
       }
    }
    return bounds;
}

void setRotationAroundCenter(Sprite sprite, float rotation)
body
{
	auto center = sprite.getCenter;
	sprite.rotation = rotation;
	auto delta = center - sprite.getCenter;
	sprite.move(delta);
}

Vector2f getCenter(Sprite sprite)
{
	auto bounds = sprite.getGlobalBounds;
	return Vector2f(
		bounds.left + bounds.width/2.,
		bounds.top + bounds.height/2.
	);
}

Vector2f getSize(Sprite sprite)
{
	auto local = sprite.getLocalBounds;
	auto scale = sprite.scale;
	return Vector2f(local.width * scale.x, local.height * scale.y);
}

void spaceMenuItems(T : MenuItem)(T[] menuItems)
{
	trace("Arranging the menu items");
	if(menuItems.empty) return;
	auto size = menuItems.front.name.getGlobalBounds;
	auto screenSize = styleOpts.screenSize;
	foreach(i, item; menuItems)
	{
		auto ypos = styleOpts.menuTop + (size.height + styleOpts.menuSpacing) * i;
		trace("Y position of ", item.description, " is ", ypos);
		item.name.position = Vector2f(0, ypos);
		item.name.center!(CenterDirection.Horizontal)
				(FloatRect(0, 0, screenSize.x, screenSize.y));
		++i;
	}
	trace("Arranged the manu items");
}




