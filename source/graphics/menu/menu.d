module mahjong.graphics.menu.menu;

import std.experimental.logger;

import dsfml.graphics.color;
import dsfml.graphics.rect;
import dsfml.graphics.rendertarget;
import dsfml.graphics.text;
import dsfml.system.vector2;

import mahjong.graphics.cache.font;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.manipulation;
import mahjong.graphics.menu.menuitem;
import mahjong.graphics.selections.selectable;

class Menu : Selectable!MenuItem
{
	this(string title)
	{
		_title = new Text;
		_title.setTitle(title);
	}
	
	void addOption(MenuItem item)
	{
		opts ~= item;
	}

   void construct()
   in
   {
     assert(opts.length > 0);
   }
   body
   {
   		spaceMenuItems(opts);
     
   }


	void configureGeometry()
	{
		opts.spaceMenuItems;
		changeOpt(0);
	}
	
	void draw(RenderTarget window)
	{
		drawSelection(window);
		drawOpts(window);
	}
	void drawSelection(RenderTarget window)
	{
		window.draw(selection.visual);
	}
	void drawOpts(RenderTarget window)
	{
		foreach(opt; opts)
		{
			opt.draw(window);
		}
	}
   
	private Text _title;
}

Menu getPauseMenu()
{
	if(_pauseMenu is null)
	{
		composePauseMenu;
	}
	return _pauseMenu;
}
private Menu _pauseMenu;
private void composePauseMenu()
{
	info("Composing pause menu");
	_pauseMenu = new Menu("");
	with(_pauseMenu)
	{
		addOption(new MenuItem("Continue", &continueGame));
		addOption(new MenuItem("New Game", &newGame));
		addOption(new MenuItem("Quit", &quitGame));
	}
	trace("Constructed all options.");
	_pauseMenu.configureGeometry;
	info("Composed pause menu");
}

private void continueGame()
{
	trace("Continuing game");
}

private void newGame()
{
	trace("Starting new game");
}

private void quitGame()
{
	trace("Quitting game");
}







