module mahjong.graphics.controllers.game.gamecontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain.player;
import mahjong.engine.gamefront;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu.menucontroller; 
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.menu.menu;
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
				selectPrevious;
				break;
			case Right:
				selectNext;
				break;
			case Space:
				tsumo;
				break;
			case Return:
				discard;
				break;
			case Escape:
				pauseGame;
				break;
			default:
		}
		return false;
	}
	
	override void roundUp()
	{
		clearPlayerCache;
		clearTileCache;
	}
	
	protected GameFront[] _gameFronts;
	protected GameFront _ownGameFront()
	{
		return _gameFronts[0];
	}
	
	protected void pauseGame()
	{
		auto pauseMenu = getPauseMenu;
		auto pauseController = new MenuController(_window, this, pauseMenu);
	}
	
	private void createSelectableHand(Player player)
	{
		trace("Creating selectable hand.");
		_hand = new SelectableHand(player.game.closedHand);
	}
	
	private void selectPrevious()
	{
		if(_hand is null) return;
		_hand.selectPrevious;
	}
	
	private void selectNext()
	{
		if(_hand is null) return;
		_hand.selectNext;
		
	}
	
	private void discard()
	{
		if(_hand is null) return;
		trace("Discarding selected item.");
		_ownGameFront.discard(_hand.selectedItem.id);
	}
	
	private void tsumo()
	{
		_ownGameFront.tsumo;
	}
	
	private SelectableHand _hand;
}







