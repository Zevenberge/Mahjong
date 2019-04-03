module mahjong.graphics.controllers.game.popup;

import std.experimental.logger;
import dsfml.graphics.renderwindow;
import dsfml.window.event;
import dsfml.window.keyboard;
import mahjong.domain.metagame;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.popup.popup;

class PopupController : GameController
{
	this(GameController underlying, 
		Popup popup)
	{
		_underlying = underlying;
		_popup = popup;
		super(underlying.getWindow(), underlying.metagame);
	}

	private Popup _popup;
	private GameController _underlying;

	override void draw() 
	{
		_underlying.draw;
		_window.draw(_popup);
		trace("Finished drawing the pop-up controller");
	}

	override void yield() {
		if(_popup.done) {
			info("Popup finished displaying. Switching to inner controller ", _underlying);
            instance = _underlying;
		}
	}

	override void substitute(Controller newController)
	{
		if(auto menu = cast(MenuController)newController)
		{
			warning("Switching the inner controller to the menu's inner controller ", 
				menu.innerController);
			_underlying = cast(GameController)menu.innerController;
		}
		else
		{
			trace("Switching the inner controller to the supplied controller ", newController);
			_underlying = cast(GameController)newController;
		}
	}

	protected override void handleGameKey(Event.KeyEvent key) 
	{
		if(key.code == Keyboard.Key.Return) 
		{
			_popup.forceFinish;
		}
		else
		{
			_underlying.handleKeyEvent(key);
		}
	}
}