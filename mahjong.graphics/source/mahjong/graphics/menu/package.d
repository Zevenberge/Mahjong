module mahjong.graphics.menu;

public import mahjong.graphics.menu.mainmenu;
public import mahjong.graphics.menu.menuitem;

import std.array;
import std.experimental.logger;

import dsfml.graphics;

import mahjong.graphics.cache.font;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.graphics.selections.selectable;
import mahjong.graphics.text;
import mahjong.util.range;

class Menu : Selectable!MenuItem
{
	this(T : MenuItem)(string title, T[] menuItems, StyleOpts styleOpts)
	{
		import mahjong.graphics.conv : toVector2f;
		foreach(item; menuItems)
		{
			addOption(item);
		}
		createTitle(title);
		spaceMenuItems(opts, styleOpts);
		_haze = new RectangleShape(styleOpts.screenSize.toVector2f);
		_haze.fillColor = styleOpts.menuHazeColor;
	}

	@("If I supply the menu items, they get set")
	unittest
	{
		import fluent.asserts;
		auto items = [new DelegateMenuItem("Yes", new DefaultStyleOpts, (){}), 
			new DelegateMenuItem("No", new DefaultStyleOpts, (){})];
		auto menu = new Menu("Continue?", items, new DefaultStyleOpts);
		menu.opts.should.equal(items);
	}

	@("The first menu option gets selected by default")
	unittest
	{
		import fluent.asserts;
		auto items = [new DelegateMenuItem("Yes", new DefaultStyleOpts, (){}), 
			new DelegateMenuItem("No", new DefaultStyleOpts, (){})];
		auto menu = new Menu("Continue?", items, new DefaultStyleOpts);
		menu.selectedItem.should.equal(items[0]);
	}

	@("The menu items should be spaced automatically")
	unittest
	{
		import fluent.asserts;
		auto items = [new DelegateMenuItem("Yes", new DefaultStyleOpts, (){}), 
			new DelegateMenuItem("No", new DefaultStyleOpts, (){})];
		auto menu = new Menu("Continue?", items, new DefaultStyleOpts);
		items[0].name.position.y.should.not.equal(0);
		items[1].name.position.y.should.not.equal(0);
		items[0].name.position.should.not.equal(items[1].name.position);
		items[0].name.position.y.should.not.equal(items[1].name.position.y);
	}

	@("On constructing, the haze is initialised propertly")
	unittest
	{
		import fluent.asserts;
		import mahjong.graphics.utils;
		auto items = [new DelegateMenuItem("Yes", new DefaultStyleOpts, (){}), 
			new DelegateMenuItem("No", new DefaultStyleOpts, (){})];
		auto menu = new Menu("Continue?", items, new DefaultStyleOpts);
		menu._haze.should.not.beNull;
		auto hazeBounds = menu._haze.getGlobalBounds;
		hazeBounds.top.should.be.lessThan(items[0].name.position.y);
		hazeBounds.bottom.should.be.greaterThan(items[1].name.getGlobalBounds.bottom);
	}

	@("On constructing, the title is set")
	unittest
	{
		import fluent.asserts;
		import mahjong.graphics.conv;
		import mahjong.graphics.utils;
		auto items = [new DelegateMenuItem("Yes", new DefaultStyleOpts, (){}), 
			new DelegateMenuItem("No", new DefaultStyleOpts, (){})];
		auto menu = new Menu("Continue?", items, new DefaultStyleOpts);
		menu._title.should.not.beNull;
		auto titleBounds = menu._title.getGlobalBounds;
		titleBounds.position.should.not.equal(Vector2f(0,0));
		titleBounds.bottom.should.be.lessThan(items[0].name.position.y);
	}

	private void createTitle(string title)
	{
		_title = new Text;
		_title.setTitle(title);
		_title.setFont(fontKanji);
	}
	
	final void addOption(MenuItem item)
	{
		opts ~= item;
	}

	void selectOption(MenuItem item)
	{
		changeOpt(opts.indexOf(item));
	}
	
	void draw(RenderTarget window)
	{
		trace("Drawing menu");
		drawHaze(window);
		drawTitle(window);
		drawSelection(window);
		drawOpts(window);
		trace("Drawn menu");
	}

	@("Drawing should include everything")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.window;
        auto window = new TestWindow();
		auto items = [new DelegateMenuItem("Yes", new DefaultStyleOpts, (){}), 
			new DelegateMenuItem("No", new DefaultStyleOpts, (){})];
		auto menu = new Menu("Continue?", items, new DefaultStyleOpts);
        menu.draw(window);
		window.drawnObjects.should.contain(
			[cast(Drawable)items[0].name, items[1].name, menu._haze, 
				menu._title, menu.selection.visual]);
    }

	private void drawHaze(RenderTarget window)
	{
		window.draw(_haze);
	}

	private void drawTitle(RenderTarget window)
	{
		window.draw(_title);
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
	private RectangleShape _haze;
}

deprecated("Supply an instance of StyleOpts instead")
void spaceMenuItems(T : MenuItem)(T[] menuItems)
{
	spaceMenuItems(menuItems, styleOpts);
}

void spaceMenuItems(T : MenuItem)(T[] menuItems, StyleOpts styleOpts)
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


