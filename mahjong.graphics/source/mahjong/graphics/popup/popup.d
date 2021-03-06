﻿module mahjong.graphics.popup.popup;

import std.experimental.logger;
import std.typecons;
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

class PlayerPopup : Popup
{
    this(string message, const Player player)
    {
        auto drawables = constructDrawables(message);
        placeDrawables(drawables[0], drawables[1], player);
        super(drawables[0], drawables[1]);
    }

    private auto constructDrawables(string message)
    {
        auto text = new Text(message.translate, kanjiFont);
        text.setCharacterSize(styleOpts.popupFontSize); 
        text.setColor(Color.Black);
        loadSplashTexture;
        auto splash = new Sprite(splashTexture);
        splash.setSize(text.getGlobalBounds.size * 1.5f);
        return tuple(text, splash);
    }

    private void placeDrawables(Text text, Sprite splash, const Player player) 
    {
        splash.centerOnIcon(player);
        text.center!(CenterDirection.Both)(splash.getGlobalBounds);
        text.move(Vector2f(0,-20));
    }

    protected override Animation constructAnimation()
    {
        return new PlayerPopupAnimation(this);
    }
}

class GamePopup : Popup
{
    this(string message)
    {
        auto drawables = constructDrawables(message);
        placeDrawables(drawables[0], drawables[1]);
        super(drawables[0], drawables[1]);
    }

    private auto constructDrawables(string message)
    {
        auto text = new Text(message.translate, kanjiFont);
        text.setCharacterSize(styleOpts.popupFontSize); 
        text.setColor(Color.Black);
        loadSplashTexture;
        auto splash = new Sprite(splashTexture);
        splash.setSize(text.getGlobalBounds.size * 1.5f);
        return tuple(text, splash);
    }

    private void placeDrawables(Text text, Sprite splash) 
    {
        splash.centerOnGameScreen!(CenterDirection.Both);
        splash.move(Vector2f(40, 0));
        text.center!(CenterDirection.Both)(splash.getGlobalBounds);
        text.move(Vector2f(0,-20));
    }

    protected override Animation constructAnimation()
    {
        return new GamePopupAnimation(this);
    }
}

abstract class Popup : Drawable
{
	this(Text text, Sprite splash)
	{
        _text = text;
        _splash = splash;
		_animation = constructAnimation();
		addAnimation(_animation);
	}

	private Text _text;
	private Sprite _splash;
	
    protected abstract Animation constructAnimation();

	private Animation _animation;

	final Animation animation() @property pure
	{
		return _animation;
	}

	alias animation this;

	final void draw(RenderTarget target, RenderStates states)
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

private class PlayerPopupAnimation : Storyboard
{
	this(Popup popup)
	{
		info("Starting player-induced pop up animation");
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

private class GamePopupAnimation : Storyboard
{
    this(Popup popup)
    {
        info("Starting game-induced pop up animation");
        auto newSplashCoords = FloatCoords(popup._splash.position + Vector2f(-50, 0), 0);
        auto newTextCoords = FloatCoords(popup._text.position + Vector2f(-50, 0), 0);
        super([
                [popup._splash.appear(25),
                    popup._text.appear(25),
                    popup._splash.moveTo(newSplashCoords, 50),
                    popup._text.moveTo(newTextCoords, 50)].parallel,
                wait(40),
                [popup._splash.fade(10), 
                    popup._text.fade(10)].parallel
            ]);
    }
}