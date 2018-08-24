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
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.graphics.rendersprite;

alias drawGame = draw;
void draw(const Metagame game, RenderTarget target)
{
	drawPlayers(game, target);
	drawWal(game, target);
	drawGameInfo(game, target);
	drawCounter(game, target);
}

void clearCache()
{
	info("Clearing metagame cache");
	clearPlayerCache;
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

private void drawGameInfo(const Metagame game, RenderTarget target)
{
	auto bounds = FloatRect(0, 900, 100, 900);
	auto renderSprite = new RenderSprite(bounds);
	auto gameInfo = getGameInfo;
	gameInfo.draw(renderSprite, game);
	target.draw(renderSprite);
}

private void drawCounter(const Metagame game, RenderTarget target)
{
	if(game.counters == 0) return;
	auto sprite = new Sprite(stickTexture);
	sprite.textureRect = hundredYenStick;
	sprite.scale = Vector2f(0.5, 0.5);
	drawingOpts.placeCounter(sprite);
	target.draw(sprite);
	if(game.counters > 1)
	{
		auto text = new Text;
		text.setColor = Color.Black;
		text.setString = "x" ~ game.counters.to!string;
		text.setFont = infoFont;
		text.setCharacterSize = 10;
		text.alignRight(sprite.getGlobalBounds);
		target.draw(text);
	}
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
	
	void draw(RenderTarget target, const Metagame game)
	{
		update(game);
		target.draw(_background);
		target.draw(_roundInfo);
		target.draw(_turnPlayerInfo);
	}
	
	private:
		Text _roundInfo;
		Text _turnPlayerInfo;
		Sprite _background;
		
		void initialise()
		{
			auto fs = styleOpts.gameInfoFontSize;
			trace("Initialising GameInfo");
			_roundInfo = new Text;
			initText(_roundInfo, Vector2f(30, 10), infoFont, fs);
			_roundInfo.setStyle(Text.Style.Bold);
			_turnPlayerInfo = new Text;
			initText(_turnPlayerInfo, Vector2f(600,51), fontReg, fs/2);
			initBg;
			trace("Initialised GameInfo");
		}
		
		void initText(Text text, Vector2f pos, Font font, int fontSize)
		{
			with(text)
			{
				setFont(font);
				setCharacterSize(fontSize);
				setColor(styleOpts.gameInfoFontColor);
				position = pos;
			}
			
		}
		
		void initBg()
		{
			auto so = styleOpts;
			_background = new Sprite(infoTexture);
			_background.setSize(so.screenSize.x -2*so.gameInfoMargin,
				so.screenSize.y - so.gameScreenSize.y - 2*so.gameInfoMargin);
			_background.position = Vector2f(so.gameInfoMargin,so.gameInfoMargin);
			_background.color = Color(255,255,255,126);
		}
		
		void update(const Metagame game)
		{
			auto roundInfo = game.leadingWind.to!int.to!Kanji.to!string;
			if(game.round > 0) roundInfo ~= game.round.toKanji;
			_roundInfo.setString(roundInfo);
			_roundInfo.center!(CenterDirection.Vertical)(_background.getGlobalBounds);
			auto currentPlayer = game.currentPlayer;
			if(currentPlayer !is null) _turnPlayerInfo.setString(currentPlayer.name.to!string);
			else _turnPlayerInfo.setString("");
		}
}



