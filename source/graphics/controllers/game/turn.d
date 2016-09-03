module mahjong.graphics.controllers.game.turn;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;

class TurnController : GameController
{
	this(RenderWindow window, Metagame metagame, TurnEvent event)
	{
		trace("Instantiating turn controller");
		_event = event;
		super(window, metagame);
	}

	private TurnEvent _event;

	override void draw()
	{
		_window.clear;
		drawGameBg(_window);
		_metagame.draw(_window);
	}

	protected override void handleGameKey(Event.KeyEvent key) 
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Left:
				// TODO Move the selection left
				break;
			case Right:
				// TODO Move the selection right
				break;
			case Return:
				// TODO Submit the selected option
				break;
			default:
				// Do nothing
				break;
		}
	}
}