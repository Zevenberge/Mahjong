module mahjong.graphics.selectable;

import dsfml.graphics;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.graphics;
import mahjong.graphics.selection;

class Selectable(T)
{
   T[] opts;
   Selection selection;
   
   this()
   {
     // Also initialise the selection.
     this.selection = Selection(new RectangleShape, 0);
     selection.visual.fillColor = Color.Red;
   }


  bool navigate(int key)
  {
     bool isEntered = false; // Check whether the enter button is pressed.
     switch(key)
     {
       case Keyboard.Key.Up, Keyboard.Key.Left:
         --selection.position;
         break;
       case Keyboard.Key.Down, Keyboard.Key.Right:
         ++selection.position;
         break;
       case Keyboard.Key.Return:
         isEntered = true;
         return isEntered;
       default:
         break;
     }
     selectOpt;
     return isEntered;
  }

  void selectOpt()
  {
    // Firstly check whether the selection does not fall out of bounds.
    correctOutOfBounds(selection.position, opts.length);
    // Construct the selection rectangle.
    FloatRect optPos = opts[selection.position].getGlobalBounds();
    selection.visual.position = Vector2f(optPos.left - selectionMargin, optPos.top - selectionMargin);
    selection.visual.size = Vector2f(optPos.width + 2 * selectionMargin, optPos.height + 2 * selectionMargin);
  }

  void changeOpt(const int i)
  {
    // Change the option to a given value i.
    selection.position = i;
    selectOpt;
  }

  FloatRect getGlobalBounds()
  {
    return calcGlobalBounds(opts);
  }

}