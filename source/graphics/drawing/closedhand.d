module mahjong.graphics.drawing.closedhand;

import std.conv;
import dsfml.graphics;
import dsfml.system.vector2;
import mahjong.domain.closedhand;
import mahjong.domain.tile;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.opts.opts;

alias drawClosedHand = draw;
void draw(ClosedHand hand, RenderTarget view)
{	
	auto cnt = hand.tiles.length;
	foreach(i, tile; hand.tiles)
	{
		tile.setCoords(FloatCoords(calculatePosition(cnt, i.to!int)));
		tile.drawTile(view);
	}
}

void placeHand(ClosedHand hand)
{
	auto cnt = hand.tiles.length;
	foreach(i, tile; hand.tiles)
	{
		tile.setCoords(FloatCoords(calculatePosition(cnt, i.to!int)));
	}
	
}

private Vector2f calculatePosition(const size_t amountOfTiles, const int number)
{
	auto screen = styleOpts.gameScreenSize;
	auto position = styleOpts.center;
	// Center the hand between two avatars
	float centering = (screen.x - drawingOpts.iconSpacing - amountOfTiles * tile.displayWidth) / 2.;
	Vector2f movement = Vector2f(
		centering + number * tile.displayWidth - position.x,
		position.y - drawingOpts.iconSize
	);
	return position + movement;
}