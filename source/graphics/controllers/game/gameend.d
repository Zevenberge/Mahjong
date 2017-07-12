module mahjong.graphics.controllers.game.gameend;

import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.gameend;
import mahjong.graphics.drawing.result;
import mahjong.graphics.opts : styleOpts;
import mahjong.graphics.utils : freeze;

class GameEndController : MahjongController
{
	this(RenderWindow window, Metagame metagame, GameEndEvent event)
	{
		super(window, metagame, freezeGameGraphicsOnATexture(metagame));
		_screen = new GameEndScreen(metagame, innerScreenBounds);
	}

	private RenderTexture freezeGameGraphicsOnATexture(Metagame metagame)
	{
		auto screen = styleOpts.screenSize;
		return freeze!((target) {})(Vector2u(screen.x, screen.y));
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