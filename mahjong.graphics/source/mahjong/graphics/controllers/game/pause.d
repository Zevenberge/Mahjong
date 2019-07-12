module mahjong.graphics.controllers.game.pause;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.menu.mainmenucontroller;
import mahjong.graphics.controllers.menu.menucontroller;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.menu.creation.mainmenu;
import mahjong.graphics.opts;

class PauseOverlay : Overlay
{
    this()
    {
        info("Composing pause menu");
	    _pauseMenu = new Menu("");
	    with(_pauseMenu)
	    {
	    	addOption(new DelegateMenuItem("Continue", &continueGame));
	    	addOption(new DelegateMenuItem("Quit", &quitGame));
	    }
	    trace("Constructed all options.");
	    _pauseMenu.configureGeometry;
        _haze = new RectangleShape(styleOpts.screenSize.toVector2f);
		_haze.fillColor = styleOpts.menuHazeColor;
	    info("Composed pause menu");
    }

    @("When I start the pause menu, continue is selected")
    unittest
    {
        import fluent.asserts;
        styleOpts = new DefaultStyleOpts;
        auto overlay = new PauseOverlay();
        overlay._pauseMenu.selectedItem.description.should.equal("Continue");
    }

    private Menu _pauseMenu;
    private RectangleShape _haze;

    private void continueGame()
    {
        Controller.instance.remove(this);
    }

    @("If I continue, the pause overlay is removed")
    unittest
    {
        import fluent.asserts;
        styleOpts = new DefaultStyleOpts;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay();
        Controller.instance.add(overlay);
        overlay.continueGame;
        Controller.instance.has(overlay).should.equal(false);
        Controller.instance.should.equal(controller);
        import core.memory;
        GC.collect;
    }

    private void quitGame()
    {
	    trace("Quitting game");
	    Controller.instance.roundUp;
	    Controller.instance.substitute(new MainMenuController(getMainMenu()));
	    trace("Returned to the main menu");
    }

    @("If I quit the game, the application returns to the main menu")
    unittest
    {
        import fluent.asserts;
        styleOpts = new DefaultStyleOpts;
        scope(exit) Controller.cleanUp;
        composeMainMenu(null, null);
        scope(exit) cleanupMainMenu;
        Controller.instance.substitute(new TestController);
        auto overlay = new PauseOverlay();
        Controller.instance.add(overlay);
        overlay.quitGame;
        Controller.instance.should.be.instanceOf!MainMenuController;
    }

    @("If I quit the game, the overlay is also removed")
    unittest
    {
        import fluent.asserts;
        styleOpts = new DefaultStyleOpts;
        scope(exit) Controller.cleanUp;
        composeMainMenu(null, null);
        scope(exit) cleanupMainMenu;
        Controller.instance.substitute(new TestController);
        auto overlay = new PauseOverlay();
        Controller.instance.add(overlay);
        overlay.quitGame;
        Controller.instance.has(overlay).should.equal(false);
    }

    override void draw(RenderTarget target) 
    {
        target.draw(_haze);
        _pauseMenu.draw(target);
    }

    @("Drawing should include the menu.")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.window;
        styleOpts = new DefaultStyleOpts;
        auto window = new TestWindow();
        auto overlay = new PauseOverlay();
        overlay.draw(window);
        window.drawnObjects.should.contain(overlay._haze);
        window.drawnObjects.length.should.be.greaterThan(3);
    }

    override bool handle(Event.KeyEvent key)
    {
        switch(key.code) with (Keyboard.Key)
		{
			case Up:
				_pauseMenu.selectPrevious;
				break;
			case Down:
				_pauseMenu.selectNext;
				break;
			case Return:
                _pauseMenu.selectedItem.select();
				break;
			case Escape:
				continueGame();
                break;
			default:
		}
        return true;
    }

    @("The pause overlay by definition overrides all game input")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        styleOpts = new DefaultStyleOpts;
        auto overlay = new PauseOverlay();
        auto isHandled = overlay.handle(gKeyPressed.key);
        isHandled.should.equal(true);
    }

    @("When I press down, the quit option is selected")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        styleOpts = new DefaultStyleOpts;
        auto overlay = new PauseOverlay();
        auto isHandled = overlay.handle(downKeyPressed.key);
        isHandled.should.equal(true);
        overlay._pauseMenu.selectedItem.description.should.equal("Quit");
        overlay.handle(downKeyPressed.key);
        overlay._pauseMenu.selectedItem.description.should.equal("Quit");
    }

    @("When I press up, the previous option is selected")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        styleOpts = new DefaultStyleOpts;
        auto overlay = new PauseOverlay();
        overlay.handle(downKeyPressed.key);
        auto isHandled = overlay.handle(upKeyPressed.key);
        isHandled.should.equal(true);
        overlay._pauseMenu.selectedItem.description.should.equal("Continue");
        overlay.handle(upKeyPressed.key);
        overlay._pauseMenu.selectedItem.description.should.equal("Continue");
    }

    @("Pressing escape again equals continuing")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        styleOpts = new DefaultStyleOpts;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay();
        Controller.instance.add(overlay);
        auto isHandled = overlay.handle(escapeKeyPressed.key);
        isHandled.should.equal(true);
        Controller.instance.has(overlay).should.equal(false);
        Controller.instance.should.equal(controller);
    }

    @("Pressing escape again equals continuing even if quit is selected")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        styleOpts = new DefaultStyleOpts;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay();
        Controller.instance.add(overlay);
        overlay.handle(downKeyPressed.key);
        auto isHandled = overlay.handle(escapeKeyPressed.key);
        isHandled.should.equal(true);
        Controller.instance.has(overlay).should.equal(false);
        Controller.instance.should.equal(controller);
    }

    @("Hitting enter selects the selected option (continue)")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        styleOpts = new DefaultStyleOpts;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay();
        Controller.instance.add(overlay);
        auto isHandled = overlay.handle(returnKeyPressed.key);
        isHandled.should.equal(true);
        Controller.instance.has(overlay).should.equal(false);
        Controller.instance.should.equal(controller);
    }

    @("Hitting enter selects the selected option (quit)")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        styleOpts = new DefaultStyleOpts;
        scope(exit) Controller.cleanUp;
        composeMainMenu(null, null);
        scope(exit) cleanupMainMenu;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay();
        Controller.instance.add(overlay);
        overlay.handle(downKeyPressed.key);
        auto isHandled = overlay.handle(returnKeyPressed.key);
        isHandled.should.equal(true);
        Controller.instance.should.be.instanceOf!MainMenuController;
    }
}


private Menu _pauseMenu;
Menu composePauseMenu()
{
	if(_pauseMenu !is null) return _pauseMenu;
	info("Composing pause menu");
	_pauseMenu = new Menu("");
	with(_pauseMenu)
	{
		addOption(new DelegateMenuItem("Continue", {continueGame;}));
		addOption(new DelegateMenuItem("Quit", {quitGame;}));
	}
	trace("Constructed all options.");
	_pauseMenu.configureGeometry;
	info("Composed pause menu");
	return _pauseMenu;
}

private void continueGame()
{
	trace("Continuing game");
	auto menuController = cast(MenuController)Controller.instance;
	if(menuController !is null)
	{
		menuController.closeMenu;
	}
	trace("Closed menu");
}

private void quitGame()
{
	import mahjong.graphics.menu.creation.mainmenu;
	trace("Quitting game");
	Controller.instance.roundUp;
	Controller.instance.substitute(new MainMenuController(getMainMenu()));
	trace("Returned to the main menu");
}
