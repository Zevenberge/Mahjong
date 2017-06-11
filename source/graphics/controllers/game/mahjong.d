module mahjong.graphics.controllers.game.mahjong;

import std.algorithm;
import std.array;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.domain.tile;
import mahjong.engine.flow.mahjong;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.opts;

class MahjongController: GameController
{
	this(RenderWindow window, Metagame metagame, MahjongEvent event)
	{
		super(window, metagame);
		_event = event;
		freezeGameGraphics;
		setHaze;
	}

	private void freezeGameGraphics()
	{
		auto screen = styleOpts.screenSize;
		auto texture = new RenderTexture;
		texture.create(screen.x, screen.y);
		_metagame.drawGame(texture);
		texture.display;
		_game = new Sprite(texture.getTexture);
	}

	private void setHaze()
	{
		auto margin = Vector2f(10,10);
		auto screen = styleOpts.screenSize;
		_haze = new RectangleShape(
			Vector2f(screen.x - 2*margin.x, screen.y - 2*margin.y));
		_haze.position = margin;
		_haze.fillColor = styleOpts.mahjongResultsHazeColor;
	}

	private void createResultScreens()
	{
		_resultScreens = _event.data.map!(mahjongData => new ResultScreen(mahjongData)).array;
		currentScreen.initialize;
	}

	private MahjongEvent _event;
	private Sprite _game;
	private RectangleShape _haze;
	private ResultScreen[] _resultScreens;
	private ResultScreen currentScreen() @property
	{
		return _resultScreens.front;
	}

	override void draw()
	{
		_window.draw(_game);
		_resultScreens.front.draw(_window);
		_window.draw(_haze);
	}

	protected override void handleGameKey(Event.KeyEvent key) 
	{
		switch(key.code) with(Keyboard.Key)
		{
			case Return:
				advanceScreen;
				break;
			default:
				// Do nothing.
				break;
		}
	}

	private void advanceScreen()
	{
		if(!currentScreen.done)
		{
			finishCurrentScreen;
		}
		else if(isThereANextScreen)
		{
			moveToNextScreen;
		}
		else
		{
			finishRound;
		}
	}

	private void finishCurrentScreen()
	{
		currentScreen.forceFinish;
	}

	private bool isThereANextScreen() @property
	{
		return _resultScreens.length > 1;
	}

	private void moveToNextScreen()
	{
		_resultScreens = _resultScreens[1.. $];
		currentScreen.initialize;
	}

	private void finishRound()
	{
		_event.handle;
		controller = new IdleController(_window, _metagame);
	}
}

private class ResultScreen
{
	this(const MahjongData mahjongData)
	{
		_mahjongData = mahjongData;
	}

	private const MahjongData _mahjongData;

	void initialize()
	{
		loadPlayerIcon;
		placeTiles;
	}

	private void loadPlayerIcon()
	{
		_playerIcon = _mahjongData.player.getIcon.dup;
		_playerIcon.rotation = 0;
		_playerIcon.position = 
			Vector2f(styleOpts.screenSize.x - 20 - drawingOpts.iconSize, 20);
	}

	private void placeTiles()
	{
		_tiles = _mahjongData.result.tiles.array;
		float initialLeftBound = 40;
		float leftBound = initialLeftBound;
		float topBound = 40;
		foreach(i, set; _mahjongData.result.sets)
		{
			if(i == 4) // Make new row.
			{
				leftBound = initialLeftBound;
				topBound += 5 + drawingOpts.tileSize.y;
			}
			foreach(tile; set.tiles)
			{
				if(tile.origin is null)
				{
					tile.move(FloatCoords(Vector2f(leftBound, topBound), 0));
					leftBound += drawingOpts.tileWidth;
				}
				else
				{
					tile.move(FloatCoords(
							Vector2f(
								leftBound + drawingOpts.tileSize.y,
								topBound + drawingOpts.tileSize.y - drawingOpts.tileSize.x
								),
							90));
					leftBound += drawingOpts.tileSize.y;
				}
			}
			leftBound += 10;
		}
	}

	private Sprite _playerIcon;
	private const(Tile)[] _tiles;

	void draw(RenderTarget target)
	{
		target.draw(_playerIcon);
		foreach(tile; _tiles)
		{
			.draw(tile, target);
		}
	}

	bool done() @property
	{
		return true;
	}

	void forceFinish()
	{

	}
}