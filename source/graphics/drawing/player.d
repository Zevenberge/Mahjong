module mahjong.graphics.drawing.player;

import std.conv;
import std.experimental.logger;
import std.uuid;

import dsfml.graphics;
import mahjong.domain.player;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.cache.font;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.ingame;
import mahjong.graphics.drawing.openhand;
import mahjong.graphics.enums.font;
import mahjong.graphics.enums.kanji;
import mahjong.graphics.enums.resources;
import mahjong.graphics.conv;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;

alias drawPlayer = draw;
void draw(Player player, RenderTarget view, float rotation)
{
	PlayerVisuals visual;
	if(player.id !in _players)
	{
		visual = new PlayerVisuals(defaultTexture, player, rotation);
		trace("Adding new player.");
		_players[player.id] = visual;
	}
	else
	{
		visual = _players[player.id];
	}
	visual.draw(view);
	if(player.game !is null) player.game.drawIngame(view);
}

void clearPlayerCache()
{
	_players.clear;
	clearIngameCache;
	trace("Cleared player cache");
}

private PlayerVisuals[UUID] _players;

private class PlayerVisuals
{
	private
	{
		RenderTexture _renderTexture;
		Sprite _sprite;
		Texture _iconTexture;
		Sprite _icon;
		Text _score;
		int _numberedScore = -1;
		int _numberedWind = -1;
		Text _wind;
		Player _player;
		
		void initialiseNewTexture()
		{
			info("Initializing new render texture");
			_renderTexture = new RenderTexture();
			_renderTexture.create(drawingOpts.iconSize, drawingOpts.iconSize);
			info("Initialised render texture");
		}
		
		void initialiseIcon(string iconFile)
		{
			info("Initialising player icon from location ", iconFile);
			_iconTexture = new Texture;
			_iconTexture.loadFromFile(iconFile);
			_icon = new Sprite(_iconTexture);
			_icon.pix2scale(drawingOpts.iconSize);
			info("Initialised player icon");
		}
		
		void initialiseScore()
		{
			info("Initialising the score");
			_score = new Text;
			_score.setFont(pointsFont);
			_score.setCharacterSize(pointsSize);
			updateScore();
			info("Initialised the score");
		}
		
		void updateScore()
		{
			trace("Updating score");
			_numberedScore = _player.score;
			_score.setString(_numberedScore.to!string);
			if(_numberedScore < drawingOpts.criticalScore)
			{
				trace("Setting the critical color");
				_score.setColor(pointsCriticalColor);
			}
			else
			{
				trace("Setting the normal color");
				_score.setColor(pointsColor);
			}
			_score.center!(CenterDirection.Both)(_scoreLabel.getGlobalBounds);
			trace("Updated the score");
		}

		void initialiseWind()
		{
			info("Initialising wind");
			_wind = new Text;
			_wind.setFont(kanjiFont);
			_wind.setCharacterSize(windSize);
			_wind.setColor(windColor);
			info("Initialised wind");
		}
		
		void initialiseSprite(float rotation)
		{
			info("Initialising player sprite");
			redrawTexture;
			_sprite = new Sprite(_renderTexture.getTexture);
			_sprite.pix2scale(styleOpts.gameScreenSize.x);
			placeSprite(rotation);
			info("Initialized player sprite");
		}
		
		void placeSprite(float rotation)
		{
			trace("Placing sprite");
			auto screen = styleOpts.gameScreenSize;
			_sprite.pix2scale(drawingOpts.iconSize);
			_sprite.position = Vector2f(
				screen.x - (drawingOpts.iconSize + drawingOpts.iconSpacing),
				screen.y - drawingOpts.iconSize
			);
			_sprite.setRotationAroundCenter(-rotation);
			trace("Placed the sprite");
		}

		void updateIfRequired()
		{
			bool updated = false;
			if(_player.wind != _numberedWind) 
			{
				updateWind;
				updated = true;
			}
			if(_player.score != _numberedScore)
			{
				updateScore;
				updated = true;
			}
			if(updated) redrawTexture;
		}

		void updateWind()
		{
			_numberedWind = _player.wind;
			if(_numberedWind < 0) return;
			auto windSymbol = _numberedWind.to!Kanji.to!string;
			trace("Updating wind");
			_wind.setString(windSymbol);
			_wind.alignTopLeft(iconBounds);
			trace("Updated wind");
		}
		void redrawTexture()
		{
			info("Redrawing the player render texture");
			with(_renderTexture)
			{
				clear(Color.Transparent);
				draw(_icon);
				draw(_scoreLabel);
				draw(_score);
				if(_wind !is null) draw(_wind);
				display;
			}
			info("Redrawn the player texture");
		}
	}
	
	public:
		void draw(RenderTarget view)
		{
			updateIfRequired;
			view.draw(_sprite);
		}
		
		this(string iconFile, Player player, float rotation)
		{
			info("Initialising player visuals");
			_player = player;
			initialiseNewTexture;
			initialiseIcon(iconFile);
			initialiseScoreLabel;
			initialiseScore();
			initialiseSprite(rotation);
			initialiseWind;
			info("Initialised player visuals");
		}
} 

private void initialiseScoreLabel()
{
	if(_scoreLabel is null)
	{
		info("Initialising score label.");
		auto texture = new Texture;
		texture.loadFromFile(sticksFile, stick);
		_scoreLabel = new Sprite(texture);
		_scoreLabel.pix2scale(drawingOpts.iconSize);
		_scoreLabel.scale = Vector2f(_scoreLabel.scale.x, 2*_scoreLabel.scale.y); // TODO unhack
		_scoreLabel.alignBottom(iconBounds);
		info("Initialised the score label");
	}
}

private FloatRect iconBounds()
{
	return FloatRect(0,0,drawingOpts.iconSize, drawingOpts.iconSize);
}

private Sprite _scoreLabel;


