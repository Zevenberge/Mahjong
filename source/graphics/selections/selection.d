module mahjong.graphics.selections.selection;

import dsfml.graphics.rectangleshape;
import dsfml.graphics.rendertarget;

struct Selection
{
	RectangleShape visual;
	int position;
	
	void draw(RenderTarget target)
	{
		target.draw(visual);
	}
}