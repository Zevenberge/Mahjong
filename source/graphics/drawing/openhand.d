module mahjong.graphics.drawing.openhand;

import std.algorithm.iteration;
import dsfml.graphics;
import mahjong.domain.openhand;
import mahjong.graphics.drawing.tile;

alias drawOpenHand = draw;
void draw(OpenHand hand, RenderTarget view)
{
	hand.sets.each!(s => s.each!(t => t.drawTile(view)));
}