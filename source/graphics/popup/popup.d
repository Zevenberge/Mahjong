module mahjong.graphics.popup.popup;

import std.experimental.logger;
import dsfml.graphics : Text, Sprite, Texture, RenderTarget, RenderStates, Drawable, Color;
import dsfml.system : Vector2f;
import mahjong.domain.player;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.fade;
import mahjong.graphics.anime.idle;
import mahjong.graphics.anime.story;
import mahjong.graphics.cache.font;
import mahjong.graphics.cache.texture;
import mahjong.graphics.conv;
import mahjong.graphics.drawing.player;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.graphics.i18n;
import mahjong.graphics.popup.service;

class Popup : Drawable
{
	this(string message, IPopupService service, const Player player)
	{
		constructDrawables(message);
		placeDrawables(player);
		constructAnimation(service);
		addAnimation(_animation);
	}

	private void constructDrawables(string message)
	{
		_text = new Text(message.translate, kanjiFont);
        _text.setCharacterSize(styleOpts.popupFontSize); 
		_text.setColor(Color.Black);
		loadSplashTexture;
		_splash = new Sprite(splashTexture);
		_splash.setSize(_text.getGlobalBounds.size * 1.5f);
	}

	private Text _text;
	private Sprite _splash;

	private void placeDrawables(const Player player) 
	{
		_splash.centerOnIcon(player);
		_text.center!(CenterDirection.Both)(_splash.getGlobalBounds);
		_text.move(Vector2f(0,-20));
	}

	private void constructAnimation(IPopupService service)
	{
		_animation = new PopupAnimation(this, service);
	}

	private Animation _animation;

	Animation animation() @property pure
	{
		return _animation;
	}

	void draw(RenderTarget target, RenderStates states)
	{
		trace("Coordinates of the splash: ", _splash.getGlobalBounds);
		trace("Color of the splash: ", _splash.color);
		trace("Coordinates of the text: ", _text.getGlobalBounds);
		trace("Color of the text: ", _text.getColor);
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

private class PopupAnimation : Storyboard
{
	this(Popup popup, IPopupService service)
	{
		info("Starting pop up animation");
		_popup = popup;
		_service = service;
		super([
				[new AppearSpriteAnimation(_popup._splash, 30),
						new AppearTextAnimation(_popup._text, 30)].parallel,
				new Idle(60),
				[new FadeSpriteAnimation(_popup._splash, 30), 
					new FadeTextAnimation(_popup._text, 30)].parallel
			]);
	}

	private Popup _popup;
	private IPopupService _service;

	protected override void onDone()
	{
		info("Finished pop up animation");
		super.onDone;
		_service.remove(_popup);
	}
}