module mahjong.graphics.drawing.openhand;

import std.algorithm.iteration;
import std.array;
import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.openhand;
import mahjong.domain.tile;
import mahjong.graphics.drawing.tile;

alias drawOpenHand = draw;
void draw(OpenHand hand, RenderTarget view)
{
	hand.getOpenHandVisuals().draw(view);
}

void clearOpenHandCache()
{
	_hands.clear;
	trace("Cleared open hand cache");
}

private:

OpenHandVisuals[UUID] _hands;

OpenHandVisuals getOpenHandVisuals(OpenHand hand)
{
	if(hand.id !in _hands)
	{
		trace("Generating new open hand visual for ", hand.id);
		auto handVisuals = new OpenHandVisuals(hand);
		_hands[hand.id] = handVisuals;
		return handVisuals;
	}
	return _hands[hand.id];
}

class OpenHandVisuals
{
	this(OpenHand hand)
	{
		_hand = hand;
	}

	void draw(RenderTarget view)
	{
		updateIfNecessary;
		_sets.each!(s => s.draw(view));
	}

	private OpenHand _hand;
	private SetVisual[] _sets;

	private void updateIfNecessary()
	{
		if(_sets.length != _hand.sets.length)
		{
			auto previousSet = _sets.empty ? null : _sets.back;
			_sets ~= new SetVisual(_hand.sets.back, previousSet);
		}
		// TODO: when kakan is implemented: also check set length
	}
}

class SetVisual
{
	this(Tile[] set, SetVisual previous)
	{
		_set = set;
		placeSet(previous);
	}

	private void placeSet(SetVisual previous)
	{

	}

	void draw(RenderTarget view)
	{
		_set.each!(t => t.drawTile(view));
	}

	private Tile[] _set;
}