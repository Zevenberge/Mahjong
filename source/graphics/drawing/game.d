module mahjong.graphics.drawing.game;

import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.wall;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts.opts;

alias drawGame = draw;
void draw(Metagame game, RenderTarget target)
{
	drawPlayers(game, target);
	drawWal(game, target);
}

private void drawPlayers(Metagame game, RenderTarget target)
{
	auto renderTexture = getPlayerTexture; 
	foreach(i, player; game.players)
	{
		auto rotation = drawingOpts.rotationPerPlayer * i.to!int;
		renderTexture.clear(Color.Transparent);
		player.drawPlayer(renderTexture, rotation);
		renderTexture.display;
		_playerSprite.setRotationAroundCenter(rotation);
		target.draw(_playerSprite);
	}
} 

private void drawWal(Metagame game, RenderTarget target)
{
	game.wall.drawWall(target);
}

private Sprite _playerSprite;
private RenderTexture _playerTexture;
private RenderTexture getPlayerTexture()
{
	if(_playerTexture is null)
	{
		auto screen = styleOpts.gameScreenSize;
		_playerTexture = new RenderTexture();
		_playerTexture.create(screen.x, screen.y);
		_playerSprite = new Sprite(_playerTexture.getTexture);
	}
	return _playerTexture;
}