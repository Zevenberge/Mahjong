module mahjong.graphics.controllers.menu.menucontrollerbase;

import dsfml.graphics;
import mahjong.graphics.controllers.controller;

abstract class MenuControllerBase(TMenu) : Controller
{
	this(RenderWindow window, TMenu menu)
	{
		super(window);
		_menu = menu;
	}
	
	override void draw()
	{
		_window.clear;
		_menu.draw(_window);
	}
	
	override bool handleKeyEvent(Event.KeyEvent key)
	{
		switch(key.code) with (Keyboard.Key)
		{
			case Up:
				_menu.selectPrevious;
				break;
			case Down:
				_menu.selectNext;
				break;
			case Return:
				optionSelected;
				break;
			case Escape:
				return true;
			default:
		}
		return false;
	}
	
	override void roundUp() {}
	
	override void yield() {}
	
	protected TMenu _menu;
	
	protected void optionSelected()
	{
		_menu.selectedItem.func();
	} 
	
	protected abstract bool menuClosed();
		
}