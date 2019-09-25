module mahjong.graphics.controllers.placeholdercontroller;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.mainmenu;
import mahjong.graphics.conv;
import mahjong.graphics.manipulation;
import mahjong.graphics.menu.creation.mainmenu;
import mahjong.graphics.opts;
import mahjong.graphics.text;

class PlaceholderController : Controller
{
	this(string message, string file, IntRect area)
	{
		trace("Constructing placeholder controller with filename ", file);
		initialiseBackground(file, area);
		initialiseMessage(message);
	}
	
	override void draw(RenderTarget target)
	{
		target.draw(_background);
		target.draw(_message);
	}
	
	override void roundUp(){}
	
	override void yield(){}
	
	protected override bool handleKeyEvent(Event.KeyEvent key)
	{
        Controller.instance.substitute(new MainMenuController(getMainMenu()));
		return false;
	}
	
	private void initialiseMessage(string message)
	{
		_message = new Text;
		_message.setTitle(message);
	}
	
	private void initialiseBackground(string filename, IntRect area)
	{
		auto texture = new Texture;
		texture.loadFromFile(filename, area);
		_background = new Sprite(texture);
		auto size = styleOpts.screenSize;
		_background.setSize(size.x, size.y);
		
	}
	private Sprite _background;
	private Text _message;
}