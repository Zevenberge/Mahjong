module mahjong.graphics.controllers.game.result;

import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine;
import mahjong.engine.flow.mahjong;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.result;
import mahjong.graphics.opts;

abstract class ResultController : GameController
{
    this(RenderWindow window, const Metagame metagame, RenderTexture background, Engine engine)
    {
        super(window, metagame, engine);
        _renderTexture = background;
        _game = new Sprite;
        _game.setTexture = background.getTexture;
        setHaze;
    }

    private void setHaze()
    {
        auto screen = styleOpts.gameScreenSize;
        _haze = new RectangleShape(
            Vector2f(screen.x - 2*margin.x, screen.y - 2*margin.y));
        _haze.position = margin;
        _haze.fillColor = styleOpts.mahjongResultsHazeColor;
    }

    protected RenderTexture _renderTexture;
    private Sprite _game;
    private RectangleShape _haze;

    override void draw()
    {
        drawGameBg(_window);
        _window.draw(_game);
        _window.draw(_haze);
    }

    protected override void handleGameKey(Event.KeyEvent key) 
    {
        switch(key.code) with(Keyboard.Key)
        {
            case Return:
                advanceScreen;
                break;
            default:
                // Do nothing.
                break;
        }
    }

    protected abstract void advanceScreen();
}