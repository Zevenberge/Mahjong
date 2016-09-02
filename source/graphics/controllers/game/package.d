module mahjong.graphics.controllers.game;

public import mahjong.graphics.controllers.game.gamecontroller;
public import mahjong.graphics.controllers.game.singleplayercontroller;

import dsfml.graphics;
import mahjong.engine.flow;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.menu;

class GameController(T : Flow) : Controller
{
	protected this(RenderWindow window, T flow)
	{
		super(window);
		this.flow = flow;
	}

	protected T flow;

	override void draw()
	{
		_window.clear;
		drawGameBg(_window);
		if(_hand !is null) _hand.draw(_window);
		_ownGameFront.metagame.draw(_window);
	}

	final override bool handleKeyEvent(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Escape:
				pauseGame;
				break;
			default:
				handleGameKey;
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
}