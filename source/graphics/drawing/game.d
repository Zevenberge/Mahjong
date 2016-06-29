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
private GameInfo getGameInfo(Metagame game)
{
	if(_gameInfo is null)
	{
		_gameInfo = new GameInfo(game);
	}
	return _gameInfo;
}

private class GameInfo
{
	this(Metagame game)
	{
		_game = game;
		initialise;
	}
	
	void draw(RenderTarget target)
	{
		update;
	}
	
	private:
		Metagame _game;
		Text _roundInfo;
		Text _turnInfo;
		Text _turnPlayerInfo;
		
		void initialise()
		{
			_roundInfo = new Text;
			with(_roundInfo)
			{
				setFont(infoFont);
				setCharacterSize(styleOpts.gameInfoFontSize);
				setColor(styleOpts.gameInfoFontColor);
			}
			_turnInfo = new Text;
			with(_turnInfo)
			{
				setFont(infoFont);
				setCharacterSize(styleOpts.gameInfoFontSize);
				setColor(styleOpts.gameInfoFontColor);
			}
			_turnPlayerInfo = new Text;
			with(_turnPlayerInfo)
			{
				setFont(infoFont);
				setCharacterSize(styleOpts.gameInfoFontSize);
				setColor(styleOpts.gameInfoFontColor);
			}
			
		}
		
		void update()
		{
			_roundInfo.setString(_game.leadingWind.to!int.to!Kanji.to!string 
				~ _game.round.toKanji);
			
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



