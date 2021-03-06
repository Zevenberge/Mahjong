module mahjong.graphics.controllers.menu.menucontrollerbase;

import dsfml.graphics;
import mahjong.graphics.controllers.controller;

abstract class MenuControllerBase(TMenu) : Controller
{
	this(TMenu menu)
	{
		_menu = menu;
	}
	
	override void draw(RenderTarget target)
	{
		target.clear;
		_menu.draw(target);
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
				return menuClosed;
			default:
		}
		return false;
	}
	
	override void roundUp() {}
	
	override void yield() {}
	
	protected TMenu _menu;
	
	protected void optionSelected()
	{
		_menu.selectedItem.select;
	} 
	
	protected abstract bool menuClosed();
		
}