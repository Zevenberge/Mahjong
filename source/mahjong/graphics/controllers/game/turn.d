module mahjong.graphics.controllers.game.turn;

import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.flow;
import mahjong.engine.sort;
import mahjong.graphics.controllers;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.game;
import mahjong.graphics.selections;
import mahjong.share.range;

class TurnController : GameController
{
	this(RenderWindow window, const Metagame metagame, TurnEvent event)
	{
		trace("Instantiating turn controller");
		_event = event;
		super(window, metagame);
		initialise;
	}

	private void initialise()
	{
		trace("Initialising selection of turn controller");
		_event.player.closedHand.displayHand;
		opts = _event.player.game.closedHand.tiles;
		initSelection();
		auto index = opts.indexOf(_event.drawnTile);
		changeOpt(index);
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
				selectPrevious;
				break;
			case Right:
				selectNext;
				break;
			case Return:
				selectedItem.confirm(_event, true);
				break;
			default:
				// Do nothing
				break;
		}
	}

	mixin Select!(const Tile);
}

void confirm(const(Tile) selectedItem, TurnEvent event, bool canCancel)
{
    auto factory = new TurnOptionFactory(selectedItem, event, canCancel);
    if(factory.isDiscardTheOnlyOption)
    {
        discardSelectedTile(event, selectedItem);
    }   
    else
    {
        showTurnOptionMenu(factory, event.metagame);
    }
}

private void discardSelectedTile(TurnEvent event, const(Tile) selectedItem)
{
    info("Discarding tile");
    Controller.instance.substitute(new IdleController(Controller.instance.getWindow(), event.metagame));
    event.discard(selectedItem);
}

private void showTurnOptionMenu(TurnOptionFactory factory, const(Metagame) metagame)
{
    Controller.instance.substitute(
        new TurnOptionController(Controller.instance.getWindow(), 
            metagame, Controller.instance, factory));
}