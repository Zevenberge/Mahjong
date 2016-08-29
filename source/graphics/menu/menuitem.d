module mahjong.graphics.menu.menuitem;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.cache.font;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.conv;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;

class MenuItem
{
	alias Action = void function();
	this(string displayName, Action action)
	{
		trace("Constructing menu item ", displayName);
		func = action;
		setText(displayName);
		description = displayName;
	}

	void draw(RenderTarget target)
	{
		target.draw(name);
	}
	
	FloatRect getGlobalBounds()
	{
		return name.getGlobalBounds;
	}
	FloatRect getLocalBounds()
	{
		return name.getLocalBounds;
	}
		
	string description;
	Text name;
	Action func;
	private void setText(string displayName)
	{
		auto text = new Text;
		with(text)
		{
			setFont(menuFont);
			setString(displayName);
			setCharacterSize(styleOpts.menuFontSize);
			setColor(styleOpts.menuFontColor);
			position = Vector2f(200,0);
		}   
		text.center!(CenterDirection.Horizontal)
			(FloatRect(0,0, styleOpts.screenSize.x, styleOpts.screenSize.y));
		name = text;
	}
}

class MainMenuItem : MenuItem
{
	Sprite background;
	
	this(string displayName, Action action, string resourceFile, IntRect textureRect)
	{
		super(displayName, action);
		auto texture = new Texture;
		texture.loadFromFile(resourceFile, textureRect);
		texture.setSmooth(true);
		background = new Sprite(texture);
		background.pix2scale(styleOpts.screenSize.x, styleOpts.screenSize.y);
	}
	
	void drawBg(RenderTarget target)
	{
		target.draw(background);
	}
}