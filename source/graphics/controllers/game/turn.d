module mahjong.graphics.controllers.game.turn;

import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.engine.mahjong;
import mahjong.graphics.controllers;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.selections;

class TurnController : GameController
{
	this(RenderWindow window, Metagame metagame, TurnEvent event)
	{
		trace("Instantiating turn controller");
		_event = event;
		super(window, metagame);
		initialise;
	}

	private TurnEvent _event;

	override void draw()
	{
		_window.clear;
		drawGameBg(_window);
		selectOpt;
		selection.draw(_window);
		_metagame.draw(_window);
	}

	protected override void handleGameKey(Event.KeyEvent key) 
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Left:
				// TODO Move the selection left
				selectPrevious;
				break;
			case Right:
				// TODO Move the selection right
				selectNext;
				break;
			case Return:
				discardSelectedTile;
				break;
			case Space:
				claimTsumo;
				break;
			default:
				// Do nothing
				break;
		}
	}

	private void discardSelectedTile()
	{
		info("Discarding tile");
		controller = new IdleController(_window, _metagame);
		_event.discard(selectedItem);
	}

	private void claimTsumo()
	{
		info("Claiming tsumo");
		controller = new IdleController(_window, _metagame);
		_event.claimTsumo;
	}

	private void initialise()
	{
		trace("Initialising selection of turn controller");
		_event.player.game.closedHand.open;
		_event.player.game.closedHand.tiles.sortHand;
		opts = _event.player.game.closedHand.tiles;
		initSelection;
		auto index = getIndexOfDrawnTile;
		changeOpt(index);
	}

	private int getIndexOfDrawnTile()
	{
		// TODO use std.algorithm.searching
		int index;
		foreach(i, tile; opts)
		{
			if(tile.id == _event.drawnTile.id)
			{
				index = i.to!int;
				break;
			}
		}
		return index;
	}

	mixin Select!Tile;
}