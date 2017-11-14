﻿module mahjong.graphics.popup.popup;

import std.experimental.logger;
import dsfml.graphics : Text, Sprite, Texture, RenderTarget, RenderStates, Drawable;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.fade;
import mahjong.graphics.cache.font;
import mahjong.graphics.cache.texture;
import mahjong.graphics.enums.resources;
import mahjong.graphics.opts;
import mahjong.graphics.i18n;
import mahjong.graphics.popup.service;

class Popup : Drawable
{
	this(string message, IPopupService service)
	{
		constructDrawables(message);
		constructAnimation(service);
	}

	private void constructDrawables(string message)
	{
		_text = new Text(message.translate, kanjiFont);
        _text.setCharacterSize(styleOpts.popupFontSize); 
		loadSplashTexture;
		_splash = new Sprite(splashTexture);
	}

	private Text _text;
	private Sprite _splash;

	private void constructAnimation(IPopupService service)
	{
		//_animation = new PopupAnimation(this, service);
	}

	private Animation _animation;

	Animation animation() @property pure
	{
		return _animation;
	}

	void draw(RenderTarget target, RenderStates states)
	{
		_splash.draw(target, states);
		_text.draw(target, states);
	}
}

private void loadSplashTexture() 
{ 
	if(splashTexture !is null) return; 
	info("Loading splash texture for popup"); 
	splashTexture = new Texture; 
	splashTexture.loadFromFile(splashFile); 
} 


private class PopupAnimation : Animation
{
	this(Popup popup, IPopupService service)
	{
		_popup = popup;
		_service = service;
	}

	private Popup _popup;
	private IPopupService _service;

	protected override void onDone()
	{
		super.onDone;
		_service.remove(_popup);
	}
}