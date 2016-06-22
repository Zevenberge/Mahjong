module mahjong.graphics.selections.selectable;

import dsfml.graphics;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.manipulation;
import mahjong.graphics.selections.selection;

class Selectable(T)
{
	T[] opts;
	Selection selection;
   
	this()
	{
		selection = Selection(new RectangleShape, 0);
		selection.visual.fillColor = Color.Red;
	}

	void selectPrevious()
	{
		--selection.position;
		selectOpt;
	}
	
	void selectNext()
	{
		++selection.position;
		selectOpt;
	}
	
	T selectedItem()
	{
		return opts[selection.position];
	}


  private void selectOpt()
  {
    // Firstly check whether the selection does not fall out of bounds.
    correctOutOfBounds(selection.position, opts.length);
    // Construct the selection rectangle.
    FloatRect optPos = opts[selection.position].getGlobalBounds();
    selection.visual.position = Vector2f(optPos.left - selectionMargin, optPos.top - selectionMargin);
    selection.visual.size = Vector2f(optPos.width + 2 * selectionMargin, optPos.height + 2 * selectionMargin);
  }

	/// Change the option to a given value i.
	protected void changeOpt(const int i)
	{
		selection.position = i;
		selectOpt;
	}

  FloatRect getGlobalBounds()
  {
    return calcGlobalBounds(opts);
  }

}