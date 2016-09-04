module mahjong.graphics.controllers.game;

public import mahjong.graphics.controllers.game.idle;
public import mahjong.graphics.controllers.game.turn;

import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.menu;

class GameController : Controller
{
	protected this(RenderWindow window, Metagame metagame)
	{
		super(window);
		_metagame = metagame;
	}

	protected Metagame _metagame;

	override void draw()
	{
		_window.clear;
		drawGameBg(_window);
		_metagame.draw(_window);
	}

	final override bool handleKeyEvent(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Escape:
				pauseGame;
				break;
			default:
				handleGameKey(key);
				break;
		}
		return false;
	}

	protected void pauseGame()
	{
		auto pauseMenu = getPauseMenu;
		auto pauseController = new MenuController(_window, this, pauseMenu);
		controller = pauseController;
	}

	protected abstract void handleGameKey(Event.KeyEvent key);

	override void roundUp() 
	{
		// Do nothing
	}

	override void yield() 
	{
		flow.advanceIfDone;
	}
}