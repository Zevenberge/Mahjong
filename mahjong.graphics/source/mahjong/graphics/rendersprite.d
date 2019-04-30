module mahjong.graphics.rendersprite;

import std.conv;
import std.experimental.logger;
import dsfml.system.vector2;
import dsfml.graphics.color;
import dsfml.graphics.drawable;
import dsfml.graphics.primitivetype;
import dsfml.graphics.rect;
import dsfml.graphics.renderstates;
import dsfml.graphics.rendertarget;
import dsfml.graphics.sprite;
import dsfml.graphics.transform;
import dsfml.graphics.transformable;
import dsfml.graphics.vertex;
import dsfml.graphics.view;
import mahjong.graphics.conv;
import mahjong.graphics.coords;
import mahjong.graphics.utils;

import dsfml.graphics.text;

class RenderSprite : Drawable, Transformable, RenderTarget
{
	private Drawable[] _drawables;
	private Vector2f _scale;
	private Vector2f _size;
	
	this(FloatRect initialRect)
	{
		_size = initialRect.size;
		this.position = initialRect.position;

	}

	void draw(Drawable drawable, RenderStates states = RenderStates.Default)
	{
		_drawables ~= drawable;
	}

	mixin NormalTransformable;
	
	void draw(RenderTarget target, RenderStates states)
	{
		states.transform *= getTransform;
		foreach(i, drawable; _drawables)
		{
			target.draw(drawable, states);
		}
	}

	void clear(Color color = Color.Black)
	{
		_drawables.destroy;
	}

	mixin NotImplementedRenderTarget;

	FloatRect getGlobalBounds() @property
	{
		return FloatRect(position, _size);
	}
}

private mixin template NotImplementedRenderTarget()
{
	void draw(Drawable drawable, RenderStates states = RenderStates.Default)
	{
		assert(false);
	}

	void clear(Color color = Color.Black)
	{
		assert(false);
	}

	void draw(const(Vertex)[] vertices, PrimitiveType type, 
		RenderStates states = RenderStates.Default)
	{
		assert(false);
	}
	const(View) view(const(View) newView) @property
	{
		assert(false);
	}
	const(View) view() const @property
	{
		assert(false);
	}
	const(View) getDefaultView() const
	{
		assert(false);
	}
	Vector2!uint getSize() const
	{
		assert(false);
	}
	IntRect getViewport(const(View) view) const
	{
		assert(false);
	}
	Vector2f mapPixelToCoords(Vector2i point) const
	{
		assert(false);
	}
	Vector2f mapPixelToCoords(Vector2i point, const(View) view) const
	{
		assert(false);
	}
	Vector2i mapCoordsToPixel(Vector2f point) const
	{
		assert(false);
	}
	Vector2i mapCoordsToPixel(Vector2f point, const(View) view) const
	{
		assert(false);
	}
	void popGLStates() {}
	void pushGLStates() {}
	void resetGLStates() {}
}