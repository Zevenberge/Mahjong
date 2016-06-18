module mahjong.engine.ai;

import std.random;
import std.uuid;

import mahjong.engine.enums.game;
import mahjong.engine.gamefront;
import mahjong.engine.mahjong;

class AI
{
	void interact()
	{
		final switch(_front.requiredInteraction) with (Interaction)
		{
			case Draw:
				draw;
				break;
			case Discard:
				discard;
				break;
			case None:
				return;
		}
	}
	
	protected:
		this(GameFront front)
		{
			_front = front;
		}
		GameFront _front;
	
		abstract void draw();
		abstract void discard();
}

class RandomAI : AI
{
	this(GameFront front)
	{
		super(front);
	}
	
	protected override void draw()
	{
		_front.draw;
	}
	
	protected override void discard()
	{
		auto player = _front.owningPlayer;
		if(player.isMahjong)
		{
			_front.tsumo;
		}
		else
		{
			auto hand = player.game.closedHand.tiles;
			auto discard = uniform(0, hand.length);
			_front.discard(hand[discard].id);
		}
	}
}

