module mahjong.graphics.drawing.wall;

import std.algorithm.iteration;
import std.experimental.logger;
import std.range;
import dsfml.graphics;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.opts.opts;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.ingame;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.game;;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;

alias drawWall = draw;
void draw(Wall wall, RenderTarget view)
{
	wall.tiles.filter!(t => !t.isOpen).each!(t => t.drawTile(view));
	wall.tiles.filter!(t => t.isOpen).each!(t => t.drawTile(view));
}

void initialiseTiles(Wall wall)
{
	info("Placing up the default wall tiles.");

	int widthOfWall = cast(int)wall.tiles.length / (2*gameOpts.amountOfPlayers);
	trace("Width of the wall is ", widthOfWall);
	auto size = TileSize;
	float undershoot = TileSize.y/TileSize.x;

	trace("Setting up wall tiles.");
	for(int i = 0; i < (wall.tiles.length/2); ++i)
	{
		trace("Placing tile pair  ",i);
		auto position = CENTER;
		auto movement = calculatePositionInSquare(widthOfWall, undershoot, 
			Vector2i(i % widthOfWall,0), FloatRect(0, 0, size.x, size.y));
		int wallSide = getWallSide(i, widthOfWall);
		trace("The tile is on the ", cast(playerLocation)wallSide, " side");
		moveToPlayer(position, movement, wallSide );
		trace("Moved the tile to its side");
		placeBottomTile(wall.tiles[$-1 - (2*i+1)],position);
		placeTopTile(wall.tiles[$-1 - (2*i)],position);
		trace("Placed the bottom and top tile");
		wall.tiles[$-1 - 2*i].rotateToPlayer(wallSide);
		wall.tiles[$-1 - (2*i+1)].rotateToPlayer(wallSide);
		trace("Rotated the tiles. Finished placing the tile");
	}
	info("Built the wall");
}

void initialiseTiles(BambooWall wall)
{
	info("Placing up the bamboo wall tiles.");
	// Place the wall in the middle
	auto position = getOutermostBambooPosition;
	for(int i = 0; i < (wall.tiles.length/2); ++i)
	{
		placeBottomTile(wall.tiles[$-1 - 2*i],position);
		placeTopTile(wall.tiles[$-2 - 2*i],position);
		position.x -= TileSize.x; 
	}
	info("Placed all tiles in the wall.");
}
private int getWallSide(const int i, const int widthOfWall)
{
	return i / widthOfWall;
}
private void placeBottomTile(const Tile tile, const Vector2f position)
{
	modifyTilePosition(tile, position, Operator.Plus);
}
private void placeTopTile(const Tile tile, const Vector2f position)
{
	modifyTilePosition(tile, position, Operator.Minus);
}
private void modifyTilePosition(const Tile tile, const Vector2f position, const Operator sign)
{
	Vector2f pos = position;
	switch(sign) with(Operator)
	{
		case Plus:
			pos.y += wallMargin;
			break;
		case Minus:
			pos.y -= wallMargin;
			break;
		default:
			assert(false);
	}
	tile.setCoords(FloatCoords(pos.x, pos.y, 0));
}
private Vector2f getOutermostBambooPosition()
{ // There are only 10 tiles left. Stack them two high. Return the position of the last tile.
	auto position = CENTER;
	position.x += 1.5 * TileSize.x; // Move the tile 1.5 tiles to the right.
	position.y -= 0.5 * TileSize.y;// Move the tile 0.5 tiles to the top.
	return position;
}
