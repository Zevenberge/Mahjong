﻿module mahjong.graphics.popup.popup;

import std.experimental.logger;
import dsfml.graphics : Text, Sprite, Texture, RenderTarget, RenderStates, Drawable, Color;
import dsfml.system : Vector2f;
import mahjong.domain.player;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.story;
import mahjong.graphics.cache.font;
import mahjong.graphics.cache.texture;
import mahjong.graphics.coords;
import mahjong.graphics.conv;
import mahjong.graphics.drawing.player;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.graphics.i18n;
import mahjong.graphics.popup.service;
import mahjong.graphics.utils;

class Popup : Drawable
{
	this(string message, const Player player)
	{
		constructDrawables(message);
		placeDrawables(player);
		constructAnimation();
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

	private void constructAnimation()
	{
		_animation = new PopupAnimation(this);
	}

	private Animation _animation;

	Animation animation() @property pure
	{
		return _animation;
	}

	alias animation this;

	void draw(RenderTarget target, RenderStates states)
	{
		trace("Coordinates of the splash: ", _splash.getGlobalBounds);
		trace("Color of the splash: ", _splash.color);
		trace("Coordinates of the text: ", _text.getGlobalBounds);
		trace("Color of the text: ", _text.getColor);
		_splash.draw(target, states);
		trace("Drawn sprite");
		_text.draw(target, states);
		trace("Drawn text");
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
	this(Popup popup)
	{
		info("Starting pop up animation");
		auto newSplashCoords = FloatCoords(popup._splash.position.transitionTowardCenter(100), 0);
		auto newTextCoords = FloatCoords(popup._text.position.transitionTowardCenter(100), 0);
		super([
				[popup._splash.appear(30),
				    popup._text.appear(30),
				    popup._splash.moveTo(newSplashCoords, 60),
				    popup._text.moveTo(newTextCoords, 60)].parallel,
				wait(20),
				[popup._splash.fade(10), 
					popup._text.fade(10)].parallel
			]);
	}
}

private Vector2f transitionTowardCenter(const Vector2f origin, float diagonalDistance)
{
	auto distance = styleOpts.center - origin;
	trace("Distance: ", distance);
	auto direction = distance.normalized;
	trace("Direction: ", direction);
	auto movement = direction * diagonalDistance;
	trace("Movement: ", movement);
	return origin + movement;
}