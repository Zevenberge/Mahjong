module mahjong.graphics.controllers.game.mahjong;

import std.algorithm.iteration;
import std.array;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine.flow.mahjong;
import mahjong.engine.scoring;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.fade;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.result;
import mahjong.graphics.drawing.transfer;
import mahjong.graphics.opts;
import mahjong.graphics.utils : freeze;

class MahjongController : GameController
{
	this(RenderWindow window, const Metagame metagame, RenderTexture background)
	{
		super(window, metagame);
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
	private MahjongEvent _event;
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

class ResultController : MahjongController
{
	this(RenderWindow window, const Metagame metagame, MahjongEvent event)
	{
		auto texture = freezeGameGraphicsOnATexture(metagame);
		_event = event;
		super(window, metagame, texture);
		createResultScreens;
	}

	private void createResultScreens()
	{
		_resultScreens = _event.data.map!(mahjongData => new ResultScreen(mahjongData, _metagame)).array;
		currentScreen.initialize;
	}

	private RenderTexture freezeGameGraphicsOnATexture(const Metagame metagame)
	{
		auto screen = styleOpts.screenSize;
		return freeze!(target => metagame.drawGame(target))(Vector2u(screen.x, screen.y));
	}

	private ResultScreen[] _resultScreens;
	private ResultScreen currentScreen() @property
	{
		return _resultScreens.front;
	}

	private MahjongEvent _event;

	override void draw()
	{
		super.draw();
		_resultScreens.front.draw(_window);
	}

	protected override void advanceScreen()
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
		Controller.instance.substitute(new TransferController(_window, _metagame, _renderTexture, _event));
	}
}

class TransferController : MahjongController
{
	this(RenderWindow window, const Metagame metagame, RenderTexture background, MahjongEvent event)
	{
		super(window, metagame, background);
		_event = event;
		composeTransferScreen;
	}

	private void composeTransferScreen()
	{
		auto transactions = _event.data.toTransactions(_metagame);
		_transferScreen = new TransferScreen(transactions);
	}

	private TransferScreen _transferScreen;
	private MahjongEvent _event;

	override void draw()
	{
		super.draw();
		_transferScreen.draw(_window);
	}

	protected override void advanceScreen()
	{
		if(!_transferScreen.done)
		{
			finishTransfer;
		}
		else
		{
			finishRound;
		}
	}

	private void finishTransfer()
	{
		_transferScreen.forceFinish;
	}

	private void finishRound()
	{
		_event.handle;
		Controller.instance.substitute(new IdleController(_window, _metagame));
	}
}

