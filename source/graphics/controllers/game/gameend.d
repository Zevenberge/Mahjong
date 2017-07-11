module mahjong.graphics.controllers.game.gameend;

import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine.flow;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.gameend;
import mahjong.graphics.drawing.result;
import mahjong.graphics.opts;

class GameEndController : MahjongController
{
	this(RenderWindow window, Metagame metagame, GameEndEvent event)
	{
		super(window, metagame, freezeGameGraphicsOnATexture(metagame));
		_screen = new GameEndScreen(metagame, innerScreenBounds);
	}

	private RenderTexture freezeGameGraphicsOnATexture(Metagame metagame)
	{
		// TODO
		auto screen = styleOpts.screenSize;
		auto texture = new RenderTexture;
		texture.create(screen.x, screen.y, true);
		metagame.drawGame(texture);
		texture.display;
		return texture;
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