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

class MahjongController : ResultController
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

