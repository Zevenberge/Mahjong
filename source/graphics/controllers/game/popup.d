module mahjong.graphics.controllers.game.popup;

import std.experimental.logger;
import dsfml.graphics.renderwindow;
import dsfml.window.event;
import dsfml.window.keyboard;
import mahjong.domain.metagame;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.controllers.menu;
import mahjong.graphics.popup.service;

class PopupController : GameController, ISubstituteInnerController
{
	this(GameController underlying, 
		IPopupService popupService)
	{
		_underlying = underlying;
		_popupService = popupService;
		super(underlying.getWindow(), underlying.metagame);
	}

	private IPopupService _popupService;
	private GameController _underlying;

	override void draw() 
	{
		_underlying.draw;
		_popupService.draw(_window);
		trace("Finished drawing the pop-up controller");
	}

	override void yield() {
		if(!_popupService.hasPopup) {
			info("Popup finished displaying. Switching to inner controller ", _underlying);
			forceSwitchController(_underlying);
		}
	}

	void substitute(Controller newController)
	{
		if(auto menu = cast(MenuController)newController)
		{
			trace("Switching the inner controller to the menu's inner controller ", 
				menu.innerController);
			_underlying = cast(GameController)menu.innerController;
		}
		else
		{
			trace("Switching the inner controller to the supplied controller ", newController);
			_underlying = cast(GameController)newController;
		}
	}

	protected override void handleGameKey(Event.KeyEvent key) {
		if(key.code == Keyboard.Key.Return) {
			_popupService.forceFinish;
		}
	}
}