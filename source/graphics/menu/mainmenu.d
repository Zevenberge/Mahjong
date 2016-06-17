module mahjong.graphics.menu.mainmenu;

import std.conv;
import std.experimental.logger;

import dsfml.graphics;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.enums.resources;;
import mahjong.graphics.graphics;
import mahjong.graphics.menu.menuitem;
import mahjong.graphics.selections.selectable;

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
	if(_menu is null) 
	{
		composeMainMenu;
	}
	return _menu;
	
}

private MainMenu _menu;
private void composeMainMenu()
{
	info("Composing main menu");
	_menu = new MainMenu("Main Menu");
	with(_menu)
	{
		addOption(new MainMenuItem("Riichi Mahjong", 
				&startRiichiMahjong, riichiFile, IntRect(314,0,2*width,2*height)));
		addOption(new MainMenuItem("Bamboo Battle", 
				&startBambooBattle, bambooFile, IntRect(314,0,4*width,4*height)));
		addOption(new MainMenuItem("Thunder Thrill", 
				&startThunderThrill, eightPlayerFile, IntRect(100,0,768,768)));
		addOption(new MainMenuItem("Simple Mahjong", 
				&startSimpleMahjong, chineseFile, IntRect(314,0,2*width,2*height)));
		addOption(new MainMenuItem("Quit", 
				&quit, quitFile, IntRect(150,0,700,700)));
	}
	trace("Constructed all options.");
	_menu.configureGeometry;
	info("Composed main menu;");
}

private void startRiichiMahjong()
{
	info("Riichi mahjong selected");
}

private void startBambooBattle()
{
	info("Bamboo battle selected");
}

private void startThunderThrill()
{
	info("Thunder thrill selected");
}

private void startSimpleMahjong()
{
	info("Simple mahjong selected");
}

private void quit()
{
	info("Quit selected");
}





