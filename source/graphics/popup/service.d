module mahjong.graphics.popup.service;

import dsfml.graphics : RenderTarget;
import mahjong.engine.notifications;
import mahjong.graphics.popup.popup;
import mahjong.graphics.i18n;
import mahjong.share.range : remove;

interface IPopupService
{
	void showPopup(string msg);
	void draw(RenderTarget target);
	void remove(Popup popup);
}

class PopupService : IPopupService, INotificationService
{
	void notify(Notification notification)
	{
		showPopup(notification.translate);
	}

	void showPopup(string msg)
	{
		_popup = new Popup(msg, this);
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

	private Popup _popup;
}