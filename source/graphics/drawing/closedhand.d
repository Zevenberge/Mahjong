module mahjong.graphics.drawing.closedhand;

import std.algorithm;
import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import dsfml.system.vector2;
import mahjong.domain.closedhand;
import mahjong.domain.tile;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.movement;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.opts;

alias drawClosedHand = draw;
void draw(ClosedHand hand, RenderTarget view)
{	
	auto cnt = hand.tiles.length;
	foreach(i, tile; hand.tiles)
	{
		moveTile(tile, i, cnt);
		tile.drawTile(view);
	}
}

void placeHand(ClosedHand hand)
{
	auto cnt = hand.tiles.length;
	foreach(i, tile; hand.tiles)
	{
		moveTile(tile, i, cnt);
	}
}

void moveTile(Tile tile, size_t i, size_t total)
{
	auto coords = tile.getCoords;
	auto newCoords = FloatCoords(calculatePosition(total, i.to!int));
	if(coords != newCoords)
	{
		auto anime = new MovementAnimation(tile.getFrontSprite, newCoords, 10);
		anime.objectId = tile.id;
		anime.addIfNonExistent;
	}
}

void displayHand(const ClosedHand closedHand)
{
	closedHand.tiles.each!(t => t.display);
}

private Vector2f calculatePosition(const size_t amountOfTiles, const int number)
{
	auto screen = styleOpts.gameScreenSize;
	auto position = styleOpts.center;
	// Center the hand between two avatars
	float centering = (screen.x - drawingOpts.iconSpacing - amountOfTiles * tile.displayWidth) / 2.;
	Vector2f movement = Vector2f(
		centering + number * tile.displayWidth - position.x,
		position.y - drawingOpts.iconSize + 1.2*tile.height
	);
	return position + movement;
}