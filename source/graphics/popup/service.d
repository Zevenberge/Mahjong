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

class PopupService : INotificationService
{
	void notify(Notification notification, const Player player)
	{
		info("Notifying about ", notification);
		auto msg = notification.translate;
		auto popup = new Popup(msg, player);
		auto gameController = cast(GameController)Controller.instance;
		if(gameController){
			Controller.instance.substitute(new PopupController(gameController, popup));
		}
	}
}