module mahjong.graphics.menu.menuitem;

import dsfml.graphics;
import mahjong.graphics.opts.opts;

class MenuItem
{
	alias Action = void function();
	this(string displayName, Action action)
	{
		func = action;
		setText(displayName);
	}

	void draw(RenderTarget target)
	{
		target.draw(name);
	}
		
	private:
		Text name;
		Action func;
		void setText(string displayName)
		{
			auto text = new Text;
			with(text)
			{
				setFont(menuFont);
				setString(text);
				setCharacterSize(drawingOpts.menuFontSize);
				setColor(drawingOpts.menuFontColor);
				position = Vector2f(200,0);
			}   
			center(text, CenterDirection.Horizontal);
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
		background = new Sprite(texture);
	}
	
	void drawBg(RenderTarget target)
	{
		target.draw(background);
	}
}