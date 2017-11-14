module mahjong.graphics.popup.service;

import dsfml.graphics : RenderTarget;
import mahjong.graphics.popup.popup;
import mahjong.share.range : remove;

interface IPopupService
{
	void showPopup(string msg);
	void draw(RenderTarget target);
	void remove(Popup popup);
}

class PopupService : IPopupService
{
	void showPopup(string msg)
	{
		_popups ~= new Popup(msg, this);
	}

	void draw(RenderTarget target)
	{
		foreach(popup; _popups)
		{
			target.draw(popup);
		}
	}

	void remove(Popup popup)
	{
		.remove!((x, y) => x == y)(_popups, popup);
	}

	private Popup[] _popups;
}