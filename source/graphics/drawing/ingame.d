module mahjong.graphics.drawing.ingame;

import std.algorithm.iteration;
import std.conv;
import std.range;
import dsfml.graphics;
import mahjong.domain.ingame;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.openhand;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;

alias drawIngame = draw;
void draw(Ingame ingame, RenderTarget view)
{
	ingame.closedHand.drawClosedHand(view);
	ingame.openHand.drawOpenHand(view);
	drawDiscards(ingame, view);
}

private void drawDiscards(Ingame ingame, RenderTarget view)
{
	placeDiscards(ingame);
	ingame.discards.each!(t => t.drawTile(view));
}

private void placeDiscards(Ingame ingame)
{
	foreach(number, tile; ingame.discards)
	{
		auto tileSize = tile.getGlobalBounds;
		auto tileIndex = getDiscardIndex(number.to!int);
		auto movement = calculatePositionInSquare(discardsPerLine, discardUndershoot,
						tileIndex, tileSize);
		auto position = CENTER;
		tile.setCoords(FloatCoords(position+movement, 0));
	}
}

private Vector2i getDiscardIndex(int number)
{
	int x = 0, y = 0;
	if(number > (discardLines-1)*discardsPerLine)
	{
		x = number - (discardLines-1)*discardsPerLine - 1;
		y = discardLines - 1;
	}
	else
	{
		x = (number-1) % discardsPerLine;
		y = (number-1)/discardsPerLine;
	}
	return Vector2i(x,y);
}

deprecated Vector2f calculatePositionInSquare(const int amountOfTiles, const float undershootInTiles, const Vector2i tileIndex, const FloatRect sizeOfTile)
{ /*
     This function calculates the position of the nth tile with in the bottom player quadrant. This function assumes that the amountOfTiles tiles form a square with an undershoot in tiles. Please note that it is the responsibility of the caller to ensure that nthTile < amountOfTiles.
     Furthermore, this function assumes an unrotated tile. It returns the draw position of the tile with respect to the center of the board. Unrotated tiles will therefore be displaye next to each other.
  */
	float delta = (amountOfTiles - undershootInTiles)* sizeOfTile.width /2; // Distance from the center to the inner line of the square.
	auto movement = Vector2f(-delta, delta);
	movement.x += sizeOfTile.width * tileIndex.x;
	movement.y += tileIndex.y * sizeOfTile.height;
	return movement;
}





