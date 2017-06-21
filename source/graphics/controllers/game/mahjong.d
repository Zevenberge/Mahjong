module mahjong.graphics.controllers.game.mahjong;

import std.algorithm.iteration;
import std.array;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine.flow.mahjong;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.fade;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.result;
import mahjong.graphics.opts;

class MahjongController: GameController
{
	this(RenderWindow window, Metagame metagame, MahjongEvent event)
	{
		super(window, metagame);
		_event = event;
		freezeGameGraphics;
		setHaze;
		createResultScreens;
	}

	private void freezeGameGraphics()
	{
		auto screen = styleOpts.screenSize;
		auto texture = new RenderTexture;
		texture.create(screen.x, screen.y, true);
		_metagame.drawGame(texture);
		texture.display;
		_game = new Sprite;
		_game.setTexture = texture.getTexture;
		_renderTexture = texture;
	}

	private void setHaze()
	{
		auto screen = styleOpts.gameScreenSize;
		_haze = new RectangleShape(
			Vector2f(screen.x - 2*margin.x, screen.y - 2*margin.y));
		_haze.position = margin;
		_haze.fillColor = styleOpts.mahjongResultsHazeColor;
	}

	private void createResultScreens()
	{
		_resultScreens = _event.data.map!(mahjongData => new ResultScreen(mahjongData, _metagame)).array;
		currentScreen.initialize;
	}

	private RenderTexture _renderTexture;
	private MahjongEvent _event;
	private Sprite _game;
	private RectangleShape _haze;
	private ResultScreen[] _resultScreens;
	private ResultScreen currentScreen() @property
	{
		return _resultScreens.front;
	}

	override void draw()
	{
		drawGameBg(_window);
		_window.draw(_game);
		_window.draw(_haze);
		_resultScreens.front.draw(_window);
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

	private void advanceScreen()
	{
		if(!currentScreen.done)
		{
			finishCurrentScreen;
		}
		else if(isThereANextScreen)
		{
			moveToNextScreen;
		}
		else
		{
			finishRound;
		}
	}

	private void finishCurrentScreen()
	{
		currentScreen.forceFinish;
	}

	private bool isThereANextScreen() @property
	{
		return _resultScreens.length > 1;
	}

	private void moveToNextScreen()
	{
		_resultScreens = _resultScreens[1.. $];
		currentScreen.initialize;
	}

	private void finishRound()
	{
		_event.handle;
		controller = new IdleController(_window, _metagame);
	}
}

