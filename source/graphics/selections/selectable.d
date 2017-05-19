module mahjong.graphics.selections.selectable;

import dsfml.graphics;
import mahjong.graphics.manipulation;
import mahjong.graphics.selections.selection;

class Selectable(T)
{
	mixin Select!T;

	this()
	{
		initSelection;
	}

	FloatRect getGlobalBounds()
	{
		return calcGlobalBounds(opts);
	}

}

mixin template Select(T)
{
	// HACK: Tile should not be imported here?
	import mahjong.graphics.drawing.tile;
	import mahjong.graphics.enums.geometry;
	import mahjong.graphics.manipulation;
	import mahjong.graphics.utils;

	T[] opts;
	Selection selection;
	
	void initSelection()
	{
		selection = Selection(new RectangleShape, 0);
		selection.visual.fillColor = Color.Red;
	}

	void selectPrevious()
	{
		if(selection.position == 0) return;
		changeOpt(selection.position - 1);
	}
	
	void selectNext()
	{
		changeOpt(selection.position + 1);
	}
	
	T selectedItem()
	{
		return opts[selection.position];
	}

	
	protected void selectOpt()
	{
		// Firstly check whether the selection does not fall out of bounds.
		correctOutOfBounds(selection.position, opts.length);
		// Construct the selection rectangle.
		FloatRect optPos = opts[selection.position].getGlobalBounds();
		selection.visual.position = Vector2f(optPos.left - selectionMargin, optPos.top - selectionMargin);
		selection.visual.size = Vector2f(optPos.width + 2 * selectionMargin, optPos.height + 2 * selectionMargin);
	}

	/// Change the option to a given value i.
	protected void changeOpt(const size_t i)
	{
		selection.position = i;
		selectOpt;
	}
}