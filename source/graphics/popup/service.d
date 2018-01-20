module mahjong.graphics.popup.service;

import std.experimental.logger;
import dsfml.graphics : RenderTarget;
import mahjong.domain.player;
import mahjong.engine.notifications;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.popup.popup;
import mahjong.graphics.i18n;
import mahjong.share.range : remove;

interface IPopupService
{
	void showPopup(string msg, const Player player);
	void draw(RenderTarget target);
	void remove(Popup popup);
	void forceFinish();
	bool hasPopup() @property pure const;
}

class PopupService : IPopupService, INotificationService
{
	void notify(Notification notification, const Player player)
	{
		info("Notifying about ", notification);
		showPopup(notification.translate, player);
	}

	void showPopup(string msg, const Player player)
	{
		_popup = new Popup(msg, this, player);
		auto gameController = cast(GameController)controller;
		if(gameController){
			switchController(new PopupController(gameController, this));
		}
	}

	void draw(RenderTarget target)
	{
		if(_popup){
			target.draw(_popup);
		}
	}

	void remove(Popup popup)
	{
		if(popup is _popup){
			_popup = null;
		}
	}

	void forceFinish() {
		if(_popup !is null) {
			_popup.animation.forceFinish;
		}
	}

	bool hasPopup() @property pure const
	{
		return _popup is null;
	}

	private Popup _popup;
}