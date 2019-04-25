module mahjong.graphics.drawing.background;

import dsfml.graphics;
import mahjong.graphics.enums.resources;

void drawGameBg(RenderTarget target)
{
	auto bg = getGameBg;
	target.draw(bg);
}

private Sprite _gameBg;

private Sprite getGameBg()
{
	if(_gameBg is null)
	{
		auto texture = new Texture;
		texture.loadFromFile(tableFile);
		_gameBg = new Sprite(texture);
	}
	return _gameBg;
}