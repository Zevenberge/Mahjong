module mahjong.graphics.menu.mainmenu;

import std.conv;

import dsfml.graphics;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.graphics;
import mahjong.graphics.menu.menuitem;
import mahjong.graphics.selections.selectable;

class MainMenu : Selectable!MainMenuItem
{
   ubyte[] opacities;
   
	void addOption(MainMenuItem item)
	{ 
		opts ~= item;
	}

   private void changeMenuBackground()
   {
      selectOpt;
      changeOpacity;
      applyColors;
   }
   private void changeOpacity()
   {
     .changeOpacity(opacities, to!int(opts.length), selection.position);
   }
   private void applyColors()
   {
      for(int i = 0; i < opts.length; ++i)
      {
        opts[i].sprite.color = Color(255,255,255,opacities[i]);
      }
   }

	void drawBg(RenderTarget target)
	{
		changeMenuBackground;
		foreach(opt; opts)
		{
			opt.drawBg(target);
		}
	}
	void draw(RenderTarget target)
	{
		drawBg(target);
		selection.draw(target);
	}
}
