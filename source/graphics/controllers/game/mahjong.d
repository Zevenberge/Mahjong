module mahjong.graphics.controllers.game.mahjong;

import std.algorithm.iteration;
import std.array;
import std.conv;
import std.experimental.logger;
import std.math;
import std.string : format;
import std.uuid;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.domain.tile;
import mahjong.engine.flow.mahjong;
import mahjong.engine.scoring;
import mahjong.engine.yaku;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.fade;
import mahjong.graphics.cache.font;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.coords;
import mahjong.graphics.drawing.background;
import mahjong.graphics.drawing.game;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.i18n;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.share.range;

class MahjongController: GameController
{
	this(RenderWindow window, Metagame metagame, MahjongEvent event)
	{
		super(window, metagame);
		_event = event;
		freezeGameGraphics;
		setHaze;
		createResultScreens;
	}

	private void freezeGameGraphics()
	{
		auto screen = styleOpts.screenSize;
		auto texture = new RenderTexture;
		texture.create(screen.x, screen.y, true);
		_metagame.drawGame(texture);
		texture.display;
		_game = new Sprite;
		_game.setTexture = texture.getTexture;
		auto animation = new FadeSpriteAnimation(_game, 60);
		animation.objectId = randomUUID;
		addUniqueAnimation(animation);
	}

	private void setHaze()
	{
		auto screen = styleOpts.gameScreenSize;
		_haze = new RectangleShape(
			Vector2f(screen.x - 2*margin.x, screen.y - 2*margin.y));
		_haze.position = margin;
		_haze.fillColor = styleOpts.mahjongResultsHazeColor;
	}

	private void createResultScreens()
	{
		_resultScreens = _event.data.map!(mahjongData => new ResultScreen(mahjongData, _metagame)).array;
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
		drawGameBg(_window);
		_window.draw(_game);
		_window.draw(_haze);
		_resultScreens.front.draw(_window);
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

private enum margin = Vector2f(50,50);
private enum innerMargin = margin*1.4;
private enum resultScreenTileSpacing = Vector2f(20,25);
private enum iconScale = 1.5;
private enum amountOfFramesPerLineOfText = 90;

private class ResultScreen
{
	this(const MahjongData mahjongData, const Metagame metagame)
	{
		_mahjongData = mahjongData;
		_metagame = metagame;
	}

	private const MahjongData _mahjongData;
	private const Metagame _metagame;

	void initialize()
	{
		loadPlayerIcon;
		placeTiles;
		createYakuTextAnimation;
	}

	private void loadPlayerIcon()
	{
		_playerIcon = _mahjongData.player.getIcon.dup;
		_playerIcon.rotation = 0;
		_playerIcon.position = 
			Vector2f(styleOpts.screenSize.x - innerMargin.x - iconScale* drawingOpts.iconSize, 
				innerMargin.y);
		_playerIcon.scale = _playerIcon.scale * iconScale;
	}

	private void placeTiles()
	{
		_tiles = _mahjongData.result.tiles.array;
		float initialLeftBound = innerMargin.x;
		float leftBound = initialLeftBound;
		float topBound = innerMargin.y;
		foreach(i, set; _mahjongData.result.sets)
		{
			if(i == 3) // Make new row.
			{
				leftBound = initialLeftBound;
				topBound += resultScreenTileSpacing.y + drawingOpts.tileSize.y;
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
			leftBound += resultScreenTileSpacing.x;
		}
	}

	private void createYakuTextAnimation()
	{
		auto scoring = calculateScoring(_mahjongData.result, _mahjongData.player, _metagame);
		auto isClosedHand = _mahjongData.player.isClosedHand;
		auto totalAmountOfFan = 0;
		foreach(yaku; scoring.yakus)
		{
			auto fan = yaku.convertToFan(isClosedHand);
			totalAmountOfFan += fan;
			createTextAndAddAnimation(yaku.translate, fan);
		}
		if(scoring.amountOfDoras > 0)
		{
			createTextAndAddAnimation("doras".translate, scoring.amountOfDoras);
		}
		createTextAndAddAnimation("total".translate, totalAmountOfFan);
		_animation.objectId = randomUUID;
		addUniqueAnimation(_animation);
	}

	private void createTextAndAddAnimation(string text, size_t fan)
	{
		auto yakuText = new YakuText(text, fan);
		_yakuTexts ~= yakuText;
		_animation = yakuText.chainAnimations(_animation);
	}

	private void placeTexts()
	{
		float top = 250;
		auto maxWidthOfYakuText = _yakuTexts.max!(yt => yt.widthOfYakuText, float);
		auto maxWidthOfFanText = _yakuTexts.max!(yt => yt.widthOfFanText, float);
		foreach(yakuText; _yakuTexts)
		{
			yakuText.alignText(top, maxWidthOfFanText, maxWidthOfYakuText);
			top += 5 + yakuText.height;
		}
	}

	private Sprite _playerIcon;
	private const(Tile)[] _tiles;
	private Animation _animation;
	private YakuText[] _yakuTexts;

	void draw(RenderTarget target)
	{
		target.draw(_playerIcon);
		foreach(tile; _tiles)
		{
			.draw(tile, target);
		}
		foreach(yakuText; _yakuTexts)
		{
			yakuText.draw(target);
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

private enum maxYakuDescriptionWidth = 500;
private enum goldenRatio = 1.618;
private float splitter()
{
	return styleOpts.gameScreenSize.x/goldenRatio;
}
private enum textMargin = 10;

private class YakuText
{
	this(string yakuName, size_t amountOfFan)
	{
		setFan(amountOfFan);
		setYakuDescription(yakuName);
	}

	private void setFan(size_t amountOfFan)
	{
		_fan = createText;
		_fan.setString("%s fan".format(amountOfFan));
	}

	private void setYakuDescription(string yakuName)
	{
		_yaku = createText;
		_yaku.setString(yakuName);
		correctYakuDescriptionWidthIfNecessary;
	}

	private void correctYakuDescriptionWidthIfNecessary()
	{
		auto width = _yaku.getLocalBounds.width;
		if(width > maxYakuDescriptionWidth)
		{
			auto newCharacterSize = _yaku.getCharacterSize * maxYakuDescriptionWidth / width;
			_yaku.setCharacterSize(newCharacterSize.floor.to!uint);
		}
	}

	private Text createText()
	{
		auto text = new Text;
		text.setFont(fontInfo);
		text.setCharacterSize(20);
		text.setColor(Color(255,255,255,0));
		return text;
	}

	private Text _fan;
	private Text _yaku;

	float height() @property const
	{
		return _fan.getLocalBounds.height;
	}

	float widthOfFanText() @property const
	{
		return _fan.getLocalBounds.width;
	}

	float widthOfYakuText() @property const
	{
		return _yaku.getLocalBounds.width;
	}

	void alignText(float top, float maxWidthOfFanText, float maxWidthOfYakuText)
	{
		alignYakuDescription(top, maxWidthOfYakuText);
		alignAmountOfFan(top, maxWidthOfFanText);
	}

	private void alignYakuDescription(float top, float maxWidthOfYakuText)
	{
		auto bounds = FloatRect(splitter - textMargin - maxWidthOfYakuText, 
			top, maxWidthOfYakuText, height);
		_yaku.alignLeft(bounds);
	}

	private void alignAmountOfFan(float top, float maxWidthOfFanText)
	{
		auto bounds = FloatRect(splitter + textMargin, top, maxWidthOfFanText, height);
		_fan.alignRight(bounds);
	}

	void draw(RenderTarget target)
	{
		target.draw(_yaku);
		target.draw(_fan);
	}

	Animation chainAnimations(Animation previousAnimation)
	{
		Animation yakuAnimation = new AppearTextAnimation(_yaku, amountOfFramesPerLineOfText);
		Animation fanAnimation = new AppearTextAnimation(_fan, amountOfFramesPerLineOfText);
		if(previousAnimation is null)
		{
			return new ParallelAnimation([yakuAnimation, fanAnimation]);
		}
		else
		{
			return new Chain!ParallelAnimation(previousAnimation, [yakuAnimation, fanAnimation]);
		}
	}
}