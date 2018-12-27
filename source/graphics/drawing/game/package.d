module mahjong.graphics.drawing.game;

import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.graphics.cache.font;
import mahjong.graphics.cache.texture;
import mahjong.graphics.conv;
import mahjong.graphics.drawing.game.info;
import mahjong.graphics.drawing.game.sticks;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.wall;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.kanji;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.graphics.utils : freeze;

alias drawGame = draw;
void draw(const Metagame game, RenderTarget target)
{
	drawPlayers(game, target);
	drawWal(game, target);
	drawGameInfo(game, target);
	drawCounter(game, target);
    drawRiichiSticks(game, target);
}

void clearCache()
{
	info("Clearing metagame cache");
    clearGameInfo;
	clearPlayerCache;
    clearSprites;
}

RenderTexture freezeGameGraphicsOnATexture(const Metagame metagame)
{
    auto screen = styleOpts.screenSize;
    return freeze!(target => metagame.drawGame(target))(Vector2u(screen.x, screen.y));
}

private void drawPlayers(const Metagame game, RenderTarget target)
{
	auto renderTexture = getPlayerTexture; 
	foreach(i, player; game.players)
	{
		auto rotation = drawingOpts.rotationPerPlayer * i.to!int;
		renderTexture.clear(Color.Transparent);
		player.drawPlayer(game.amountOfPlayers, renderTexture, rotation);
		renderTexture.display;
		_playerSprite.setRotationAroundCenter(rotation);
		target.draw(_playerSprite);
	}
} 

private void drawWal(const Metagame game, RenderTarget target)
{
	if(game.wall is null) return;
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



