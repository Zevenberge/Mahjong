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
import mahjong.graphics.menu.creation.pausemenu;
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
	return composePauseMenu;
}





