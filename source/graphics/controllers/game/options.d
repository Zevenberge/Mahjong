module mahjong.graphics.controllers.game.options;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.string;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow.claim;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.opts;

class IngameOptionsController(Factory, string menuTitle) : MenuController 
	if(isIngameOptionsFactory!Factory)
{
	this(RenderWindow window, 
		Metagame metagame,
		Controller innerController,
		Factory factory)
	{
		auto menu = new Menu(menuTitle);
		foreach(option; factory.options)
		{
			menu.addOption(option);
		}
		menu.configureGeometry;
		selectDefaultOption(menu, factory);
		super(window, innerController, menu);
		_metagame = metagame;
	}

	private void selectDefaultOption(Menu menu, Factory factory)
	{
		static if(hasDefaultOption!Factory)
		{
			menu.selectOption(factory.defaultOption);
		}
		else
		{
			menu.selectOption(factory.options.back);
		}
	}

	private Metagame _metagame;

	void swapIdleController()
	{
		auto idleController = cast(IdleController)_innerController;
		if(!idleController)
		{
			idleController = new IdleController(_window, _metagame);
		}
		controller = idleController;
	}

	override void draw() 
	{
		if(controller == this) 
		{
			super.draw;
			drawMarkersOnRelevantTiles;
		}
		else _innerController.draw;
	}

	private void drawMarkersOnRelevantTiles()
	{
		auto selectedOption = cast(IRelevantTiles)_menu.selectedItem;
		auto rectangleShape = new RectangleShape(drawingOpts.tileSize);
		rectangleShape.fillColor = Color(250, 255, 141, 146);
		foreach(tile; selectedOption.relevantTiles)
		{
			auto coords = tile.getCoords;
			rectangleShape.position = coords.position;
			rectangleShape.rotation = coords.rotation;
			_window.draw(rectangleShape);
		}
	}

	protected override bool menuClosed() 
	{
		controller = new MenuController(_window, this, getPauseMenu);
		return false;
	}

	protected override RectangleShape constructHaze() 
	{
		auto margin = Vector2f(styleOpts.ingameMenuMargin, styleOpts.ingameMenuMargin);
		auto menuBounds = _menu.getGlobalBounds;
		auto haze = new RectangleShape(menuBounds.size + margin*2);
		haze.fillColor = styleOpts.ingameMenuHazeColor;
		haze.position = menuBounds.position - margin;
		return haze;
	}
}

template isIngameOptionsFactory(Factory)
{
	import std.range;
	import std.traits;
	enum bool isIngameOptionsFactory()
	{ 
		static if(__traits(compiles, (Factory.init).options))
		{
			return isOptionsARangeOfMenuItemsWithRelevantTiles!(ReturnType!(__traits(getMember, Factory.init, "options")));
		}
		else
		{
			return false;
		}
	}

	template isOptionsARangeOfMenuItemsWithRelevantTiles(TReturn)
	{
		enum bool isOptionsARangeOfMenuItemsWithRelevantTiles =
			isInputRange!TReturn && is(typeof(
					(inout int = 0)
					{
						TReturn t = TReturn.init;
						IRelevantTiles r = t.front;
						MenuItem m = t.front;
					}));
	}
}

interface IRelevantTiles
{
	const(Tile)[] relevantTiles() @property;
}

unittest
{
	class ValidOption : DelegateMenuItem, IRelevantTiles
	{
		this()
		{
			super("", (){});
		}

		const(Tile)[] relevantTiles() @property
		{
			return null;
		}
	}
	class ValidFactory
	{
		ValidOption[] options() @property
		{
			return null;
		}
	}
	assert(isIngameOptionsFactory!ValidFactory, "The factory and its options are valid, so the template should return true.");
}
unittest
{
	class ValidOption : DelegateMenuItem, IRelevantTiles
	{
		this()
		{
			super("", (){});
		}

		const(Tile)[] relevantTiles() @property
		{
			return null;
		}
	}
	class InValidFactory
	{
		ValidOption[] notMyOptions() @property
		{
			return null;
		}
	}
	assert(!isIngameOptionsFactory!InValidFactory, "The factory is not valid, so the template should return false.");
}
unittest
{
	class InvalidOption : DelegateMenuItem
	{
		this()
		{
			super("", (){});
		}
	}
	class ValidFactory
	{
		InvalidOption[] options() @property
		{
			return null;
		}
	}
	assert(!isIngameOptionsFactory!ValidFactory, "The options is not valid, so the template should return false.");
}
unittest
{
	class InvalidOption : IRelevantTiles
	{
		const(Tile)[] relevantTiles() @property
		{
			return null;
		}
	}
	class ValidFactory
	{
		InvalidOption[] options() @property
		{
			return null;
		}
	}
	assert(!isIngameOptionsFactory!ValidFactory, "The options is not valid, so the template should return false.");
}

template hasDefaultOption(Factory)
{
	enum bool hasDefaultOption = __traits(compiles, (Factory.init).defaultOption);
}

unittest
{
	class FactoryWithoutDefaultOption
	{

	}

	assert(!hasDefaultOption!FactoryWithoutDefaultOption, "The factory has no default option");
}

unittest
{
	class FactoryWithDefaultOption
	{
		int defaultOption()@property
		{
			return 0;
		}
	}

	assert(hasDefaultOption!FactoryWithDefaultOption, "The factory has a default option");
}