module mahjong.graphics.menu;

import dsfml.graphics.color;
import dsfml.graphics.rect;
import dsfml.graphics.renderwindow;
import dsfml.graphics.text;
import dsfml.system.vector2;

import mahjong.graphics.cache.font;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.graphics;
import mahjong.graphics.selectable;

class Menu : Selectable!Text
{
   void addOption(dstring text)
   {
     auto opt = new Text;
     with(opt)
     {
        setFont(menuFont);
        setString(text);
        setCharacterSize(32);
        setColor(Color.Black);
        position = Vector2f(200,0);
     }   
     CenterText(opt,"horizontal");
     opts ~= opt;
   }

   void construct()
   in
   {
     assert(opts.length > 0);
   }
   body
   {
     /*
       Take care of the layout of the menu. For now, let all menus begin at a set height and be centered.
     */
     enum MenuTop = 250; // Distance to the top of the screen.
     enum MenuSpacing = 20; // Distance between two text boxes.
     FloatRect size = opts[0].getGlobalBounds();
     uint i = 0;
     foreach(opt; opts)
     {
       float ypos;
       ypos = MenuTop + (size.height + MenuSpacing)*i;
       opt.position = Vector2f(0, ypos);
       CenterText(opt, "horizontal");
       ++i;
     } 
   }


   void draw(ref RenderWindow window)
   {
      drawSelection(window);
      drawOpts(window);
   }
  void drawSelection(ref RenderWindow window)
  {
     window.draw(selection.visual);
  }
  void drawOpts(ref RenderWindow window)
   {
     foreach(opt; opts)
     {
       window.draw(opt);
     }
   }
}