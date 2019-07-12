module mahjong.graphics.menu;

public import mahjong.graphics.menu.mainmenu;
public import mahjong.graphics.menu.menuitem;

import std.array;
import std.experimental.logger;

import dsfml.graphics.color;
import dsfml.graphics.rect;
import dsfml.graphics.rendertarget;
import dsfml.graphics.text;
import dsfml.system.vector2;

import mahjong.graphics.cache.font;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.graphics.selections.selectable;
import mahjong.graphics.text;
import mahjong.util.range;

class Menu : Selectable!MenuItem
{
	this(T : MenuItem)(string title, T[] menuItems)
	{
		foreach(item; menuItems)
		{
			addOption(item);
		}
	}

	@("If I supply the menu items, they get set")
	unittest
	{
		import fluent.asserts;
		auto items = [new DelegateMenuItem("Yes", (){}), 
			new DelegateMenuItem("No", (){})];
		auto menu = new Menu("Continue?", items);
		menu.opts.should.equal(items);
	}

	@("The first menu option gets selected by default")
	unittest
	{
		import fluent.asserts;
		auto items = [new DelegateMenuItem("Yes", (){}), 
			new DelegateMenuItem("No", (){})];
		auto menu = new Menu("Continue?", items);
		menu.selectedItem.should.equal(items[0]);
	}

	deprecated("Use the constructor with menu items instead")
	this(string title)
	{
		_title = new Text;
		_title.setTitle(title);
	}
	
	void addOption(MenuItem item)
	{
		opts ~= item;
	}

	void selectOption(MenuItem item)
	{
		changeOpt(opts.indexOf(item));
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
	private void drawSelection(RenderTarget window)
	{
		window.draw(selection.visual);
	}
	private void drawOpts(RenderTarget window)
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
	import mahjong.graphics.controllers.game.pause;
	return composePauseMenu;
}

void spaceMenuItems(T : MenuItem)(T[] menuItems)
{
	trace("Arranging the menu items");
	if(menuItems.empty) return;
	auto size = menuItems.front.name.getGlobalBounds;
	auto screenSize = styleOpts.screenSize;
	foreach(i, item; menuItems)
	{
		auto ypos = styleOpts.menuTop + (size.height + styleOpts.menuSpacing) * i;
		trace("Y position of ", item.description, " is ", ypos);
		item.name.position = Vector2f(0, ypos);
		item.name.center!(CenterDirection.Horizontal)
				(FloatRect(0, 0, screenSize.x, screenSize.y));
		++i;
	}
	trace("Arranged the menu items");
}



