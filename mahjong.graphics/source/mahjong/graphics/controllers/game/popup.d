module mahjong.graphics.controllers.game.popup;

import std.experimental.logger;
import dsfml.graphics.rendertarget;
import dsfml.window.event;
import dsfml.window.keyboard;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.popup.popup;

class PopupController : GameController
{
	this(GameController underlying, 
		Popup popup)
	in(underlying, "Cannot depend on null underlying controller")
	in(!cast(PopupController)underlying, "Popupception")
	{
		_underlying = underlying;
		_popup = popup;
		super(underlying.metagame, null);
	}

	private Popup _popup;
	private Controller _underlying;

	override void draw(RenderTarget target) 
	{
		_underlying.draw(target);
		target.draw(_popup);
		trace("Finished drawing the pop-up controller");
	}

	override void roundUp()
	{
		info("Rounding up popup controller");
		_underlying.roundUp;
	}

	override void yield() 
	{
		if(_popup.done) {
			info("Popup finished displaying. Switching to inner controller ", _underlying);
            instance = _underlying;
		}
	}

	override void substitute(Controller newController)
	{
		/+if(auto menu = cast(MenuController)newController)
		{
			warning("Switching the inner controller to the menu's inner controller ", 
				menu.innerController);
			newController = menu.innerController;
		}
		else
		{
			trace("Switching the inner controller to the supplied controller ", newController);
		}+/
		if(this is newController) return;
		assert(!cast(PopupController)newController, "Creating pop-up ception");
		_underlying = newController;
	}

	protected override void handleGameKey(Event.KeyEvent key) 
	{
		if(key.code == Keyboard.Key.Return) 
		{
			_popup.forceFinish;
		}
		else
		{
			if(auto gameController = cast(GameController)_underlying)
			{
				gameController.handleKeyEvent(key);
			}
		}
	}
}