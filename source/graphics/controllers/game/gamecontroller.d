module mahjong.graphics.controllers.game.gamecontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain.player;
import mahjong.engine.gamefront;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.selections.selectablehand;

abstract class GameController : Controller
{
	protected this(RenderWindow window, GameFront[] gameFronts)
	{
		super(window);
		_gameFronts = gameFronts;
		_ownGameFront.connect(&createSelectableHand);
	}
	
	override void draw()
	{
		_window.clear;
		drawGameBg(_window);
		_ownGameFront.metagame.draw(_window);
	}
	
	override bool handleKeyEvent(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Left:
			case Right:
			case Return:
			case Escape:
			default:
		}
		return false;
		
	}
	
	protected GameFront[] _gameFronts;
	protected GameFront _ownGameFront()
	{
		return _gameFronts[0];
	}
	
	private void createSelectableHand(Player player)
	{
		_hand = new SelectableHand(player.game.closedHand);
	}
	
	private SelectableHand _hand;
}







