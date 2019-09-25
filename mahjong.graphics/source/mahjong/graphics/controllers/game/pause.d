module mahjong.graphics.controllers.game.pause;

import std.experimental.logger;
import dsfml.graphics;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.mainmenu;
import mahjong.graphics.conv;
import mahjong.graphics.menu;
import mahjong.graphics.menu.creation.mainmenu;
import mahjong.graphics.opts;

class PauseOverlay : Overlay
{
    this(StyleOpts styleOpts)
    {
        info("Composing pause menu");
	    _pauseMenu = new Menu("", [
                new DelegateMenuItem("Continue", styleOpts, &continueGame),
	    	    new DelegateMenuItem("Quit", styleOpts, &quitGame)
            ], styleOpts);	    
	    trace("Constructed all options.");
    }

    @("When I start the pause menu, continue is selected")
    unittest
    {
        import fluent.asserts;
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        overlay._pauseMenu.selectedItem.description.should.equal("Continue");
    }

    private Menu _pauseMenu;

    private void continueGame()
    {
        Controller.instance.remove(this);
    }

    @("If I continue, the pause overlay is removed")
    unittest
    {
        import fluent.asserts;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        Controller.instance.add(overlay);
        overlay.continueGame;
        Controller.instance.has(overlay).should.equal(false);
        Controller.instance.should.equal(controller);
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
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
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
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        Controller.instance.add(overlay);
        overlay.quitGame;
        Controller.instance.has(overlay).should.equal(false);
    }

    override void draw(RenderTarget target) 
    {
        _pauseMenu.draw(target);
    }

    @("Drawing should include the menu.")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.window;
        styleOpts = new DefaultStyleOpts;
        auto window = new TestWindow();
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        overlay.draw(window);
        window.drawnObjects.length.should.be.greaterThan(3);
    }

    override bool handle(Event event)
    {
        if(event.type != Event.EventType.KeyReleased) return false;
        switch(event.key.code) with (Keyboard.Key)
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
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        auto isHandled = overlay.handle(gKeyPressed);
        isHandled.should.equal(true);
    }

    @("When I press down, the quit option is selected")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        auto isHandled = overlay.handle(downKeyPressed);
        isHandled.should.equal(true);
        overlay._pauseMenu.selectedItem.description.should.equal("Quit");
        overlay.handle(downKeyPressed);
        overlay._pauseMenu.selectedItem.description.should.equal("Quit");
    }

    @("When I press up, the previous option is selected")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        overlay.handle(downKeyPressed);
        auto isHandled = overlay.handle(upKeyPressed);
        isHandled.should.equal(true);
        overlay._pauseMenu.selectedItem.description.should.equal("Continue");
        overlay.handle(upKeyPressed);
        overlay._pauseMenu.selectedItem.description.should.equal("Continue");
    }

    @("Pressing escape again equals continuing")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        Controller.instance.add(overlay);
        auto isHandled = overlay.handle(escapeKeyPressed);
        isHandled.should.equal(true);
        Controller.instance.has(overlay).should.equal(false);
        Controller.instance.should.equal(controller);
    }

    @("Pressing escape again equals continuing even if quit is selected")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        Controller.instance.add(overlay);
        overlay.handle(downKeyPressed);
        auto isHandled = overlay.handle(escapeKeyPressed);
        isHandled.should.equal(true);
        Controller.instance.has(overlay).should.equal(false);
        Controller.instance.should.equal(controller);
    }

    @("Hitting enter selects the selected option (continue)")
    unittest
    {
        import fluent.asserts;
        import mahjong.test.key;
        scope(exit) Controller.cleanUp;
        auto controller = new TestController;
        Controller.instance.substitute(controller);
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        Controller.instance.add(overlay);
        auto isHandled = overlay.handle(returnKeyPressed);
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
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        Controller.instance.add(overlay);
        overlay.handle(downKeyPressed);
        auto isHandled = overlay.handle(returnKeyPressed);
        isHandled.should.equal(true);
        Controller.instance.should.be.instanceOf!MainMenuController;
    }

    @("Doing something else than key release does nothing")
    unittest
    {
        import fluent.asserts;
        auto overlay = new PauseOverlay(new DefaultStyleOpts);
        auto isHandled = overlay.handle(Event(Event.EventType.Resized));
        isHandled.should.equal(false);
    }
}