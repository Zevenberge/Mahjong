module mahjong.graphics.selections.selection;

import dsfml.graphics.rectangleshape;
import dsfml.graphics.rendertarget;
import mahjong.graphics.coords;

struct Selection
{
	RectangleShape visual;
	int position;
	
	void draw(RenderTarget target)
	{
		target.draw(visual);
	}
	
	void setCoords(FloatCoords coords)
	{
		visual.position = coords.position;
		visual.rotation = coords.rotation;
	}
}