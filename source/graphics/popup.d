module mahjong.graphics.popup;

import std.experimental.logger;
import std.uuid;
import dsfml.graphics;
import mahjong.graphics.cache.font;
import mahjong.graphics.cache.texture;
import mahjong.graphics.conv;
import mahjong.graphics.coords;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;
import mahjong.graphics.meta;
import mahjong.graphics.opts.opts;

class Popup
{
	UUID id;
	
	this(string text)
	{
		initialiseText(text);
		initialiseSplash;
		id = randomUUID;
	}
	
	void animate()
	{
		
	}
	
	mixin delegateCoords!([_text.stringof, _splash.stringof]);
	
	private: 
		Text _text;
		Sprite _splash;
		
		void initialiseText(string text)
		{
			_text = new Text;
			with(_text)
			{
				setFont(kanjiFont);
				setString(text);
				setCharacterSize(styleOpts.popupFontSize);
			}
			_text.center!(CenterDirection.Both)(styleOpts.gameScreenSize.toVector2f.toRect);
		}
		void initialiseSplash()
		{
			loadSplashTexture;
			_splash = new Sprite(splashTexture);
		}
}

private void loadSplashTexture()
{
	if(splashTexture !is null) return;
	info("Loading splash texture for popup");
	splashTexture = new Texture;
	splashTexture.loadFromFile(splashFile);
}



