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
import mahjong.graphics.graphics;
import mahjong.graphics.opts.opts;

alias drawPlayer = draw;
void draw(Player player, RenderTarget view)
{
	PlayerVisuals visual;
	if(player.id !in players)
	{
		visual.initialise(defaultTexture, player.score, player.getWind.to!Kanji.to!string);
	}
	else
	{
		visual = players[player.id];
	}
	player.game.drawIngame(view);
}

private PlayerVisuals[UUID] players;

private struct PlayerVisuals
{
	private
	{
		RenderTexture _renderTexture;
		Sprite _sprite;
		Texture _iconTexture;
		Sprite _icon;
		Text _score;
		int _numberedScore;
		Text _wind;
		
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
		
		void initialiseScore(int score)
		{
			info("Initialising the score");
			_score = new Text;
			_score.setFont(pointsFont);
			_score.setCharacterSize(pointsSize);
			updateScore(score);
			info("Initialised the score");
		}
		
		void updateScore()
		{
			trace("Updating score");
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
			_score.center(CenterDirection.Both, _scoreLabel.getGlobalBounds);
			trace("Updated the score");
		}

		void initialiseWind(string wind)
		{
			info("Initialising wind");
			_wind = new Text;
			_wind.setFont(kanjiFont);
			_wind.setCharacterSize(windSize);
			_wind.setColor(windColor);
			updateWind(wind);
			info("Initialised wind");
		}
		
		void initialiseSprite()
		{
			info("Initialising player sprite");
			_sprite = new Sprite(_renderTexture.getTexture);
			_sprite.pix2scale(width);
			placeSprite;
			info("Initialized player sprite");
		}
		
		void placeSprite()
		{
			trace("Placing sprite");
			_sprite.pix2scale(drawingOpts.iconSize);
			// TODO: Rotate for the various players.
			_sprite.position = Vector2f(
				width - (drawingOpts.iconSize + drawingOpts.iconSpacing),
				height - drawingOpts.iconSize
			);
			trace("Placed the sprite");
		}
	}
	
	public:
		void draw(RenderTarget view)
		{
			view.draw(_sprite);
		}
		
		void initialise(string iconFile, int score, string wind)
		{
			info("Initialising player visuals");
			initialiseNewTexture;
			initialiseIcon(iconFile);
			initialiseScoreLabel;
			initialiseScore(score);
			initialiseWind(wind);
			initialiseSprite;
			info("Initialised player visuals");
		}
		
		void updateScore(int score)
		{
			trace("Updating score");
			_numberedScore = score;
			updateScore;
			trace("Updated score");
		}
		
		void updateWind(string wind)
		{
			trace("Updating wind");
			_wind.setString(wind);
			_wind.alignTopLeft(iconBounds);
			trace("Updated wind");
		}
		
		void update(Player player)
		{
			info("Updating player");
			updateScore(player.score);
			updateWind(player.getWind.to!Kanji.to!string);
			info("Updated player");
		}
		
		void redrawTexture()
		{
			info("Redrawing the player render texture");
			_renderTexture.clear(Color.Transparent);
			_renderTexture.draw(_icon);
			_renderTexture.draw(_scoreLabel);
			_renderTexture.draw(_score);
			_renderTexture.draw(_wind);
			_renderTexture.display;
			info("Redrawn the player texture");
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


