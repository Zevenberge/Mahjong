module mahjong.graphics.controllers.game.gameend;

import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.gameend;
import mahjong.graphics.drawing.result;

class GameEndController : MahjongController
{
	this(RenderWindow window, Metagame metagame, RenderTexture background, GameEndEvent event)
	{
		super(window, metagame, background);
		_screen = new GameEndScreen(metagame, innerScreenBounds);
	}

	private GameEndEvent _event;
	private GameEndScreen _screen;

	override void draw() 
	{
		super.draw;
		_screen.draw(_window);
	}

	protected override void advanceScreen() 
	{
		// TODO
	}
}