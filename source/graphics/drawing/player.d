module mahjong.graphics.drawing.player;

import std.conv;
import std.experimental.logger;
import std.uuid;

import dsfml.graphics;
import mahjong.domain.player;
import mahjong.graphics.cache.font;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.ingame;
import mahjong.graphics.drawing.openhand;
import mahjong.graphics.enums.font;
import mahjong.graphics.enums.resources;
import mahjong.graphics.graphics;
import mahjong.graphics.opts.opts;

alias drawPlayer = draw;
void draw(Player player, RenderTarget view)
{
	if(player.id !in players)
	{
		
	}
	player.game.drawIngame(view);
}

private PlayerVisuals[UUID] players;

private struct PlayerVisuals
{
	private:
		RenderTexture _renderTexture;
		Sprite _sprite;
		Texture _iconTexture;
		Sprite _icon;
		Text _score;
		int _numberedScore;
		Text _wind;
		
		void initialiseNewTexture()
		{
			_renderTexture = new RenderTexture();
			_renderTexture.create(drawingOpts.iconSize, drawingOpts.iconSize);
		}
		
		void initialiseIcon(string iconFile)
		{
			_iconTexture = new Texture;
			_iconTexture.loadFromFile(iconFile);
			_icon = new Sprite(_iconTexture);
			_icon.pix2scale(drawingOpts.iconSize);
		}
		
		void initialiseScore(int score)
		{
			_score = new Text;
			_score.setFont(pointsFont);
			_score.setCharacterSize(pointsSize);
			updateScore(score);
		}
		
		void updateScore()
		{
			_score.setString(_numberedScore.to!string);
			if(_numberedScore < drawingOpts.criticalScore)
			{
				_score.setColor(pointsCriticalColor);
			}
			else
			{
				_score.setColor(pointsColor);
			}
			_score.center(CenterDirection.Both, _scoreLabel.getGlobalBounds);
		}

		void initialiseWind(string wind)
		{
			_wind = new Text;
			_wind.setFont(kanjiFont);
			_wind.setCharacterSize(windSize);
			_wind.setColor(windColor);
			updateWind(wind);
		}
		
		void initialiseSprite()
		{
			_sprite = new Sprite(_renderTexture);
			_sprite.pix2scale(width);
			placeSprite;
		}
		
		void placeSprite()
		{
			_sprite.pix2scale(iconSize);
			// TODO: Rotate for the various players.
			_sprite.position = Vector2f(
				width - (drawingOpts.iconSize + drawingOpts.iconSpacing),
				height - iconSize
			);
		}
	
	public:
		void draw(RenderTarget view)
		{
			view.draw(_sprite);
		}
		
		void initialise(string iconFile, int score, string wind)
		{
			trace("Initialising player visuals");
			initialiseIcon(iconFile);
			initialiseScoreLabel;
			initialiseScore(score);
			initialiseWind(wind);
			initialiseSprite;
		}
		
		void updateScore(int score)
		{
			_numberedScore = score;
			updateScore;
		}
		
		void updateWind(string wind)
		{
			_wind.setString(wind);
			_wind.alignTopLeft(iconBounds);
		}
		
		void update(Player player)
		{
			updateScore(player.score);
		}
		
		void redrawTexture()
		{
			trace("Redrawing the player render texture");
			_renderTexture.clear(Color.Transparent);
			_renderTexture.draw(_icon);
			_renderTexture.draw(_scoreLabel);
			_renderTexture.draw(_score);
			_renderTexture.draw(_wind);
		}
} 

private void initialiseScoreLabel()
{
	if(_scoreLabel is null)
	{
		trace("Initialising score label.");
		auto texture = new Texture;
		texture.loadFromFile(sticksFile, stick);
		_scoreLabel = new Sprite(texture);
		_scoreLabel.pix2scale(drawingOpts.iconSize);
		_scoreLabel.scale = Vector2f(_scoreLabel.scale.x, 2*_scoreLabel.scale.y); // TODO unhack
		_scoreLabel.alignBottom(iconBounds);
	}
}

private FloatRect iconBounds()
{
	return FloatRect(0,0,drawingOpts.iconSize, drawingOpts.iconSize);
}

private Sprite _scoreLabel;


