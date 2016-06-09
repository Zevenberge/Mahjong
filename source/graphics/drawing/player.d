module mahjong.graphics.drawing.player;

import std.experimental.logger;
import std.uuid;

import dsfml.graphics;
import mahjong.domain.player;
import mahjong.graphics.drawing.closedhand;
import mahjong.graphics.drawing.ingame;
import mahjong.graphics.drawing.openhand;
import mahjong.graphics.enums.resources;
import mahjong.graphics.graphics;
import mahjong.graphics.opts.opts;

alias drawPlayer = draw;
void draw(Player player, RenderTarget view)
{
	
	player.ingame.drawIngame(view);
}

private struct PlayerVisuals
{
	private:
		RenderTexture _renderTexture;
		Texture _iconTexture;
		Sprite _icon;
		Text _score;
		Text _wind;
		
		void initialiseNewTexture()
		{
			_renderTexture = new RenderTexture();
			_renderTexture.create(activeOpts.iconSize, activeOpts.iconSize);
		}
		
		void initialiseIcon(string iconFile)
		{
			_iconTexture = new Texture;
			_iconTexture.loadFromFile(iconFile);
			_icon = new Sprite(_iconTexture);
			_icon.pix2scale(activeOpts.iconSize);
		}

	
	public:
		void draw(RenderTarget view)
		{
			
		}
		
		void initialise(string iconFile, int score, string wind)
		{
			trace("Initialising player visuals");
			initialiseIcon(iconFile);
			initialiseScoreLabel;
		}
		
		void redrawTexture()
		{
			trace("Redrawing the player render texture");
			_renderTexture.clear(Color.Transparent);
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
	}
}

private Sprite _scoreLabel;


