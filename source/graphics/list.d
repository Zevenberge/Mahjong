module mahjong.graphics.list;

import std.algorithm.comparison;
import dsfml.graphics;
import mahjong.graphics.rendersprite;
import mahjong.graphics.traits;

class List : Transformable, Drawable
{
	this(Vector2f position, float margin)
	{
		this.position = position;
		this.margin = margin;
	}

	const float margin;

	mixin NormalTransformable;

	private TransformingDrawable[] _items;
	void opOpAssign(string op, T:Drawable)(T drawable)
		if(hasGlobalBounds!T)
	{
		static if(op == "~")
		{
			auto newItem = TransformingDrawable(drawable);
			auto boundsOfNewItem = drawable.getGlobalBounds;
			auto xSize = max(_size.x, boundsOfNewItem.width);
			auto ySize = _size.y + boundsOfNewItem.height;
			if(_items.length > 0)
			{
				newItem.position = Vector2f(0, _size.y + margin);
				ySize += margin;
			}
			else
			{
				newItem.position = Vector2f(0, _size.y);
			}
			_size = Vector2f(xSize, ySize);
			_items ~= newItem;
		}
		else
		{
			static assert(0, "Op " ~ op ~ " not supported");
		}
	}

	void draw(RenderTarget target, RenderStates states)
	{
		states.transform *= getTransform;
		foreach(i, drawable; _items)
		{
			drawable.draw(target, states);
		}
	}

	private Vector2f _size = Vector2f(0,0);
	FloatRect getGlobalBounds()
	{
		return getTransform.transformRect(FloatRect(position, _size));
	}
}

unittest
{
	import fluent.asserts;
	import mahjong.test.window;
	auto list = new List(Vector2f(0,0), 100);
	auto shape = new RectangleShape;
	list ~= shape;
	auto window = new TestWindow;
	list.draw(window, RenderStates.Default);
	window.drawnObjects.length.should.equal(1)
		.because("A single drawable should have been transferred to the window");
	assert(window.drawnObjects[0] == shape, "In the end of the chain, only the multi-smurfed shape is transferred to the window.");
}

unittest
{
	import fluent.asserts;
	auto list = new List(Vector2f(0,0), 100);
	auto shape1 = new RectangleShape(Vector2f(100, 150));
	auto shape2 = new RectangleShape(Vector2f(90, 250));
	list ~= shape1;
	list ~= shape2;
	list.getGlobalBounds.should.equal(FloatRect(0, 0, 100, 500))
		.because("The max width of the items should be combined with the total height");
}

unittest
{
	import fluent.asserts;
	auto list = new List(Vector2f(0,0), 100);
	auto shape1 = new RectangleShape(Vector2f(100, 150));
	auto shape2 = new RectangleShape(Vector2f(90, 250));
	list ~= shape1;
	list ~= shape2;
	list._items[0].position.should.equal(Vector2f(0,0))
		.because("the first item should not have a margin added to its position");
	list._items[1].position.should.equal(Vector2f(0,250))
		.because("the second item should have the margin added to its position");
}
unittest
{
	import fluent.asserts;
	auto list = new List(Vector2f(0,0), 100);
	auto shape1 = new RectangleShape(Vector2f(100, 150));
	auto shape2 = new RectangleShape(Vector2f(90, 250));
	auto shape3 = new RectangleShape(Vector2f(40, 100));
	list ~= shape1;
	list ~= shape2;
	list ~= shape3;
	list.getGlobalBounds.should.equal(FloatRect(0, 0, 100, 700))
		.because("every item should have an added margin");
}


private struct TransformingDrawable
{
	this(Drawable drawable)
	{
		_drawable = drawable;
	}

	private Drawable _drawable;

	mixin NormalTransformable;

	void draw(RenderTarget target, RenderStates states)
	{
		states.transform *= getTransform;
		target.draw(_drawable, states);
	}
}