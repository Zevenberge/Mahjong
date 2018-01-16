module mahjong.graphics.controllers.game.popup;

import dsfml.graphics.renderwindow;
import dsfml.window.event;
import dsfml.window.keyboard;
import mahjong.domain.metagame;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.popup.service;

class PopupController : GameController
{
	this(RenderWindow window, const Metagame metagame, GameController underlying, 
		IPopupService popupService)
	{
		_underlying = underlying;
		_popupService = popupService;
		super(window, metagame);
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
			controller = _underlying;
		}
	}

	protected override void handleGameKey(Event.KeyEvent key) {
		if(key.code == Keyboard.Key.Return) {
			_popupService.forceFinish;
		}
	}
}