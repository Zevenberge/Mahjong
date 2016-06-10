module mahjong.graphics.drawing.game;

import std.conv;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.wall;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.graphics;

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
		renderTexture.clear(Color.Transparent);
		player.drawPlayer(renderTexture);
		renderTexture.display;
		_playerSprite.rotateToPlayer(i.to!int);
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
		_playerTexture = new RenderTexture();
		_playerTexture.create(width, height);
		_playerSprite = new Sprite(_playerTexture.getTexture);
	}
	return _playerTexture;
}