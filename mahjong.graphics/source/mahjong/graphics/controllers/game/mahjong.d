module mahjong.graphics.controllers.game.mahjong;

import std.algorithm.iteration;
import std.array;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.domain.scoring;
import mahjong.engine;
import mahjong.engine.flow.mahjong;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.fade;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.result;
import mahjong.graphics.opts;

class MahjongController : ResultController
{
	this(const Metagame metagame, MahjongEvent event, Engine engine)
	{
		auto texture = freezeGameGraphicsOnATexture(metagame);
		_event = event;
		super(metagame, texture, engine);
		createResultScreens;
	}

	private void createResultScreens()
	{
		_resultScreens = _event.data.map!(mahjongData => new ResultScreen(mahjongData, _metagame)).array;
		currentScreen.initialize;
	}
	
	private ResultScreen[] _resultScreens;
	private ResultScreen currentScreen() @property
	{
		return _resultScreens.front;
	}

	private MahjongEvent _event;

	override void draw(RenderTarget target)
	{
		super.draw(target);
		_resultScreens.front.draw(target);
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
		Controller.instance.substitute(
            new TransferController!MahjongEvent(_metagame, _renderTexture, 
                _event, _event.data.toTransactions(_metagame), _engine));
	}
}

