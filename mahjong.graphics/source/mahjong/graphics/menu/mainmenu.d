module mahjong.graphics.menu.mainmenu;

import std.conv;
import std.experimental.logger;

import dsfml.graphics;
import mahjong.graphics.manipulation;
import mahjong.graphics.menu;
import mahjong.graphics.menu.creation.mainmenu;
import mahjong.graphics.selections.selectable;
import mahjong.graphics.text;

class MainMenu : Selectable!MainMenuItem
{
	this(string title)
	{
		_title = new Text;
		_title.setTitle(title);
	}
	
   ubyte[] opacities;
   
	void addOption(MainMenuItem item)
	{ 
		opts ~= item;
		opacities ~= 0;
	}

   private void changeMenuBackground()
   {
      changeOpacity;
      applyColors;
   }
   private void changeOpacity()
   {
     .changeOpacity(opacities, selection.position);
   }
   private void applyColors()
   {
      for(int i = 0; i < opts.length; ++i)
      {
        opts[i].background.color = Color(255,255,255,opacities[i]);
      }
   }

	private void drawOpts(RenderTarget target)
	{
		foreach(opt; opts)
		{
			opt.draw(target);
		}
	}
	private void drawBg(RenderTarget target)
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
		drawOpts(target);
		target.draw(_title);
	}
	
	void configureGeometry()
	{
		opts.spaceMenuItems;
		changeOpt(0);
	}
	
	private Text _title;
}

MainMenu getMainMenu()
{
	return composeMainMenu;
}




