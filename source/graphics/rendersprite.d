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
	private TransformingDrawable[] _drawables;
	private FloatCoords _transform;
	private Vector2f _scale;
	private FloatRect _size;
	
	this(FloatRect initialRect)
	{
		_size = initialRect;
		_transform.x = initialRect.left;
		_transform.y = initialRect.top;
	}
	
	void draw(RenderTarget target, RenderStates states)
	{
		foreach(i, drawable; _drawables)
		{
			drawable.transformCoords(_transform);
			target.draw(drawable, states);
			drawable.untransformCoord;
		}
	}
	Vector2f position(Vector2f newPosition) @property
	{
		_transform.position = newPosition;
		return newPosition;
	}
	Vector2f position() const @property
	{
		return _transform.position;
	}
	Vector2f origin() const @property
	{
		return Vector2f(0,0);
	}
	Vector2f origin(Vector2f newOrigin) @property
	{
		return Vector2f(0,0);
	}
	float rotation() const @property
	{
		return _transform.rotation;
	}
	float rotation(float newRotation) @property
	{
		return _transform.rotation = newRotation;
	}
	Vector2f scale() const @property
	{
		return _scale;
	}
	Vector2f scale(Vector2f newScale) @property
	{
		return _scale = newScale;
	}
	const(Transform) getTransform() const
	{
		auto tf = unity;
		auto pos = _transform.position;
		tf.translate(pos.x, pos.y);
		tf.rotate(_transform.rotation);
		tf.scale(_scale.x, _scale.y);
		return tf;
	}
	const(Transform) getInverseTransform() const
	{
		return getTransform.getInverse;
	}
	void move(Vector2f offSet)
	{
		_transform.move(offSet);
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
		auto transformed  = getTransform.transformRect(_size);
		return Vector2!uint(transformed.width.to!uint, transformed.height.to!uint);
	}
	IntRect getViewport(const(View) view) const
	{
		assert(false);
	}
	void clear(Color color = Color.Black)
	{
		_drawables.destroy;
	}
	void draw(Drawable drawable, RenderStates states = RenderStates.Default)
	{
		_drawables ~= TransformingDrawable(drawable, states);
	}
	void draw(const(Vertex)[] vertices, PrimitiveType type, 
		RenderStates states = RenderStates.Default)
	{
		assert(false);
	}
	Vector2f mapPixelToCoords(Vector2i point) const
	{
		return getTransform.transformPoint(point.toVector2f);
	}
	Vector2f mapPixelToCoords(Vector2i point, const(View) view) const
	{
		assert(false);
	}
	Vector2i mapCoordsToPixel(Vector2f point) const
	{
		return getInverseTransform.transformPoint(point).toVector2i;
	}
	Vector2i mapCoordsToPixel(Vector2f point, const(View) view) const
	{
		assert(false);
	}
	void popGLStates() {}
	void pushGLStates() {}
	void resetGLStates() {}
}

private struct TransformingDrawable
{
	this(Drawable subject, RenderStates rstates) 
	{
		obj = subject;
		states = rstates;
		auto tf = cast(Transformable)obj;
		if(tf !is null)
		{
			origCoords = FloatCoords(tf.position, tf.rotation);
		}
	}
	
	Drawable obj;
	RenderStates states;
	const(FloatCoords) origCoords;
	
	void transformCoords(FloatCoords transform)
	{
		auto tf = cast(Transformable)obj;
		if(tf is null) return;
		tf.position = origCoords.position + transform.position;
		tf.rotation = origCoords.rotation + transform.rotation;
	}
	
	void untransformCoord()
	{
		auto tf = cast(Transformable)obj;
		if(tf is null) return;
		tf.position = origCoords.position;
		tf.rotation = origCoords.rotation;
	}
	
	alias obj this;
}