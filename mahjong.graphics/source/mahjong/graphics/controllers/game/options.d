module mahjong.graphics.controllers.game.options;

import std.algorithm;
import std.array;
import std.experimental.logger;
import std.string;
import dsfml.graphics;
import mahjong.domain;
import mahjong.domain.chi;
import mahjong.engine;
import mahjong.engine.flow.claim;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.opts;

class IngameOptionsController(Factory, string menuTitle) : GameController 
	if(isIngameOptionsFactory!Factory)
{
	this(const Metagame metagame,
		Factory factory, Engine engine)
	{
		super(metagame, engine);
		_menu = new Menu(menuTitle, factory.options, styleOpts);
		selectDefaultOption(factory);
		_haze = constructHaze;
		trace("Constructed ingame options controller");
	}

	private void selectDefaultOption(Factory factory)
	{
		static if(hasDefaultOption!Factory)
		{
			_menu.selectOption(factory.defaultOption);
		}
		else
		{
			_menu.selectOption(factory.options.back);
		}
	}

	private Menu _menu;
	private RectangleShape _haze;

	protected override void handleGameKey(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Up:
				_menu.selectPrevious;
				break;
			case Down:
				_menu.selectNext;
				break;
			case Return:
				finishedSelecting;
				_menu.selectedItem.select;
				break;
			default:
				break;
		}
	}

	private void finishedSelecting()
	{
		info("Finished selecting an option. Swapping out idle controller.");
		substitute(new IdleController(_metagame, _engine));
	}

	override void draw(RenderTarget target) 
	{
		super.draw(target);
		if(!isPaused) 
		{
			drawMarkersOnRelevantTiles(target);
			target.draw(_haze);
			_menu.draw(target);
		}
	}

	private void drawMarkersOnRelevantTiles(RenderTarget target)
	{
		auto selectedOption = cast(IRelevantTiles)_menu.selectedItem;
		auto rectangleShape = new RectangleShape(drawingOpts.tileSize);
		rectangleShape.fillColor = Color(250, 255, 141, 146);
		foreach(tile; selectedOption.relevantTiles)
		{
			auto coords = tile.getCoords;
			rectangleShape.position = coords.position;
			rectangleShape.rotation = coords.rotation;
			target.draw(rectangleShape);
		}
	}

	private RectangleShape constructHaze() 
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

@("Is a factory that supplies valid options a valid factory?")
unittest
{
	class ValidOption : DelegateMenuItem, IRelevantTiles
	{
		this()
		{
			super("", new DefaultStyleOpts, (){});
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

@("If a factory does not supply an options property, it is not valid")
unittest
{
	class ValidOption : DelegateMenuItem, IRelevantTiles
	{
		this()
		{
			super("", new DefaultStyleOpts, (){});
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

@("If a factory supplies invalid options, it is not valid.")
unittest
{
	class InvalidOption : DelegateMenuItem
	{
		this()
		{
			super("", new DefaultStyleOpts, (){});
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

@("If the factory provides no menu items, it is not valid")
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

@("If my factory has no default, it is seen as such")
unittest
{
	class FactoryWithoutDefaultOption
	{

	}

	assert(!hasDefaultOption!FactoryWithoutDefaultOption, "The factory has no default option");
}

@("If my factory has a default option, it is introspected as such.")
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