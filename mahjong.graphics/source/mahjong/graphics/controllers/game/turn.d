module mahjong.graphics.controllers.game.turn;

import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine;
import mahjong.engine.flow;
import mahjong.graphics.controllers;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.game;
import mahjong.graphics.selections;
import mahjong.util.range;

class TurnController : GameController
{
	this(const Metagame metagame, 
	    TurnEvent event, Engine engine)
	{
		trace("Instantiating turn controller");
		_event = event;
		super(metagame, engine);
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

	override void draw(RenderTarget target)
	{
		target.clear;
		drawGameBg(target);
		selectOpt;
		selection.draw(target);
		_metagame.draw(target);
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
				selectedItem.confirm(_event, true, _engine);
				break;
			default:
				// Do nothing
				break;
		}
	}

	mixin Select!(const Tile);
}

void confirm(const(Tile) selectedItem, TurnEvent event, bool canCancel, Engine engine)
{
    auto factory = new TurnOptionFactory(selectedItem, event, canCancel);
    if(factory.isDiscardTheOnlyOption)
    {
        discardSelectedTile(event, selectedItem, engine);
    }   
    else
    {
        showTurnOptionMenu(factory, event.metagame, engine);
    }
}

private void discardSelectedTile(TurnEvent event, const(Tile) selectedItem, Engine engine)
{
    info("Discarding tile");
    Controller.instance.substitute(new IdleController(event.metagame, engine));
    event.discard(selectedItem);
}

private void showTurnOptionMenu(TurnOptionFactory factory, const(Metagame) metagame, Engine engine)
{
    Controller.instance.substitute(
        new TurnOptionController(metagame, Controller.instance, factory, engine));
}