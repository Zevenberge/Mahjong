module mahjong.graphics.drawing.game;

import std.conv;
import std.experimental.logger;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.graphics.cache.font;
import mahjong.graphics.cache.texture;
import mahjong.graphics.conv;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.wall;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.kanji;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts.opts;
import mahjong.graphics.rendersprite;

alias drawGame = draw;
void draw(Metagame game, RenderTarget target)
{
	drawPlayers(game, target);
	drawWal(game, target);
	drawGameInfo(game, target);
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

private void drawGameInfo(Metagame game, RenderTarget target)
{
	auto bounds = FloatRect(0, 900, 100, 900);
	auto renderSprite = new RenderSprite(bounds);
	auto gameInfo = getGameInfo;
	gameInfo.draw(renderSprite, game);
	target.draw(renderSprite);
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

private GameInfo _gameInfo;
private GameInfo getGameInfo()
{
	if(_gameInfo is null)
	{
		_gameInfo = new GameInfo;
	}
	return _gameInfo;
}

private class GameInfo
{
	this()
	{
		initialise;
	}
	
	void draw(RenderTarget target, Metagame game)
	{
		update(game);
		target.draw(_roundInfo);
		target.draw(_turnInfo);
		target.draw(_turnPlayerInfo);
	}
	
	private:
		Text _roundInfo;
		Text _turnInfo;
		Text _turnPlayerInfo;
		
		void initialise()
		{
			trace("Initialising GameInfo");
			_roundInfo = new Text;
			initText(_roundInfo, Vector2f(30, 10), infoFont);
			_turnInfo = new Text;
			initText(_turnInfo, Vector2f(600,10), fontReg);
			_turnPlayerInfo = new Text;
			initText(_turnPlayerInfo, Vector2f(600,50), fontReg);
		}
		
		void initText(Text text, Vector2f pos, Font font)
		{
			with(text)
			{
				setFont(font);
				setCharacterSize(styleOpts.gameInfoFontSize);
				setColor(styleOpts.gameInfoFontColor);
				position = pos;
			}
			
		}
		
		void update(Metagame game)
		{
			_roundInfo.setString(game.leadingWind.to!int.to!Kanji.to!string 
				~ game.round.toKanji);
			_roundInfo.center(CenterDirection.Vertical, FloatRect(0,0,900,100));
			_turnPlayerInfo.setString(game.currentPlayer.name.to!string);
			_turnInfo.setString(game.phase.to!string);
		}
}

private Texture getInfoBg()
{
	if(infoTexture is null)
	{
		infoTexture = new Texture;
		load(infoTexture, infoBgFile);
	}
	return infoTexture;
} 



