module mahjong.graphics.controllers.game.popup;

import dsfml.graphics.renderwindow;
import dsfml.window.event;
import dsfml.window.keyboard;
import mahjong.domain.metagame;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.popup.service;

class PopupController : GameController, ISubstrituteInnerController
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
	}

	override void yield() {
		if(!_popupService.hasPopup) {
			switchController(_underlying);
		}
	}

	void substitute(Controller newController)
	{
		_underlying = cast(GameController)newController;
	}

	protected override void handleGameKey(Event.KeyEvent key) {
		if(key.code == Keyboard.Key.Return) {
			_popupService.forceFinish;
		}
	}
}