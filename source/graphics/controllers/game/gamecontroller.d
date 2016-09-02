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
import mahjong.graphics.menu;
import mahjong.graphics.selections.selectablehand;

/+abstract class GameController : Controller
{
	protected this(RenderWindow window, GameFront[] gameFronts)
	{
		super(window);
		_gameFronts = gameFronts;
		connectSelectableHand;
	}
	
	override void draw()
	{
		_window.clear;
		drawGameBg(_window);
		if(_hand !is null) _hand.draw(_window);
		_ownGameFront.metagame.draw(_window);
	}
	
	override bool handleKeyEvent(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Left:
				selectPrevious;
				break;
			case Down:
				drawTile;
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
		controller = pauseController;
	}
	
	private void connectSelectableHand()
	{
		trace("Connecting selectable hand to hand creation");
		_ownGameFront.connect(&createSelectableHand);
		auto player = _ownGameFront.owningPlayer;
		if(player !is null && player.game !is null && player.game.closedHand !is null)
		{
			_hand = new SelectableHand(player.game.closedHand);
		}
	}
	
	private void createSelectableHand(Player player)
	{
		trace("Creating selectable hand.");
		_hand = new SelectableHand(player.game.closedHand);
	}
	
	private void selectPrevious()
	{
		if(_hand is null) return;
		trace("Selecting previous tile");
		_hand.selectPrevious;
	}
	
	private void selectNext()
	{
		if(_hand is null) return;
		trace("Selecting next tile");
		_hand.selectNext;
		
	}
	
	private void drawTile()
	{
		trace("Drawing tile from wall");
		_ownGameFront.draw;
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
}+/







