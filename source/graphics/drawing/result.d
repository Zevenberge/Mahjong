module mahjong.graphics.drawing.result;

import std.array;
import std.conv;
import std.experimental.logger;
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
import mahjong.graphics.coords;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.i18n;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.share.range;

enum margin = Vector2f(50,50);
private enum innerMargin = margin*1.4;
private enum resultScreenTileSpacing = Vector2f(20,25);
private enum iconScale = 1.5;
private enum amountOfFramesPerLineOfText = 90;

public class ResultScreen
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
		info("Initialising result screen");
		loadPlayerIcon;
		placeTiles;
		createYakuTextAnimation;
		placeTexts;
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
		auto scoring = calculateScoring(_mahjongData, _metagame);
		auto isClosedHand = _mahjongData.player.isClosedHand;
		createFanTexts(scoring, isClosedHand);
		createMiscTexts(scoring, isClosedHand);
		_animation.objectId = randomUUID;
		addUniqueAnimation(_animation);
	}

	private void createFanTexts(Scoring scoring, bool isClosedHand)
	{
		auto totalAmountOfFan = 0;
		foreach(yaku; scoring.yakus)
		{
			auto fan = yaku.convertToFan(isClosedHand);
			totalAmountOfFan += fan;
			createYakuTextAndAddAnimation(yaku.translate, fan);
		}
		if(scoring.amountOfDoras > 0)
		{
			totalAmountOfFan += scoring.amountOfDoras;
			createYakuTextAndAddAnimation("doras".translate, scoring.amountOfDoras);
		}
		createYakuTextAndAddAnimation("total".translate, totalAmountOfFan);
	}

	private void createMiscTexts(Scoring scoring, bool isClosedHand)
	{
		auto minipoints = new DoubleText("Minipoints", scoring.miniPoints.to!string);
		addTextAndAnimation(minipoints);
		auto score = new DoubleText("Score", 
			scoring.calculatePayment(_mahjongData.isWinningPlayerEast).ron.to!string);
		addTextAndAnimation(score);
	}

	private void createYakuTextAndAddAnimation(string text, size_t fan)
	{
		auto yakuText = new YakuText(text, fan);
		addTextAndAnimation(yakuText);
	}

	private void addTextAndAnimation(DoubleText text)
	{
		_yakuTexts ~= text;
		_animation = text.chainAnimations(_animation);
	}

	private void placeTexts()
	{
		float top = iconScale * drawingOpts.iconSize + 10 + innerMargin.y;
		auto maxWidthOfYakuText = _yakuTexts.max!(yt => yt.widthOfLeftText, float);
		trace("Max width of the yaku text is ", maxWidthOfYakuText);
		auto maxWidthOfFanText = _yakuTexts.max!(yt => yt.widthOfRightText, float);
		trace("Max width of the fan text is ", maxWidthOfFanText);
		foreach(yakuText; _yakuTexts)
		{
			trace("Top is ", top);
			yakuText.alignText(top, maxWidthOfYakuText, maxWidthOfFanText, splitter);
			top += 5 + yakuText.height;
		}
	}

	private Sprite _playerIcon;
	private const(Tile)[] _tiles;
	private Animation _animation;
	private DoubleText[] _yakuTexts;

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
		trace("Forcing the result screen to short-circuit its animations");
	}
}

private enum textMargin = 10;
private enum maxYakuDescriptionWidth = 500;
private enum goldenRatio = 1.618;
private float splitter()
{
	return styleOpts.gameScreenSize.x/goldenRatio;
}

unittest
{
	class TestStyleOpts : DefaultStyleOpts
	{
		override Vector2i gameScreenSize()
		{
			return Vector2i(1618, 0);
		}
	}
	styleOpts = new TestStyleOpts;
	assert(splitter == 1000, "The splitter should be at the larger end of the golden ratio");
	styleOpts = null;
}

private class YakuText : DoubleText
{
	this(string yakuName, size_t amountOfFan)
	{
		super(yakuName, "%s fan".format(amountOfFan));
	}
}

private class DoubleText
{
	this(string leftText, string rightText)
	{
		setLeftText(leftText);
		setRightText(rightText);
	}

	private void setRightText(string text)
	{
		_rightText = createText;
		_rightText.setString(text);
	}

	private void setLeftText(string yakuName)
	{
		_leftText = createText;
		_leftText.setString(yakuName);
		correctYakuDescriptionWidthIfNecessary;
	}

	private void correctYakuDescriptionWidthIfNecessary()
	{
		auto width = _leftText.getLocalBounds.width;
		if(width > maxYakuDescriptionWidth)
		{
			auto newCharacterSize = _leftText.getCharacterSize * maxYakuDescriptionWidth / width;
			_leftText.setCharacterSize(newCharacterSize.floor.to!uint);
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

	private Text _leftText;
	private Text _rightText;

	float height() @property const
	{
		return _rightText.getLocalBounds.height;
	}

	float widthOfRightText() @property const
	{
		return _rightText.getLocalBounds.width;
	}

	float widthOfLeftText() @property const
	{
		return _leftText.getLocalBounds.width;
	}

	void alignText(float top, float maxWidthOfLeftText, float maxWidthOfRightText, float splitter)
	{
		alignLeftTextLeft(top, maxWidthOfLeftText, splitter);
		alightRightTextRight(top, maxWidthOfRightText, splitter);
	}

	private void alignLeftTextLeft(float top, float maxWidthOfLeftText, float splitter)
	{
		auto bounds = FloatRect(splitter - textMargin - maxWidthOfLeftText, 
			top, maxWidthOfLeftText, height);
		_leftText.alignLeft(bounds);
	}

	private void alightRightTextRight(float top, float maxWidthOfRightText, float splitter)
	{
		auto bounds = FloatRect(splitter + textMargin, top, maxWidthOfRightText, height);
		_rightText.alignRight(bounds);
	}

	void draw(RenderTarget target)
	{
		target.draw(_leftText);
		target.draw(_rightText);
	}

	Animation chainAnimations(Animation previousAnimation)
	{
		Animation yakuAnimation = new AppearTextAnimation(_leftText, amountOfFramesPerLineOfText);
		Animation fanAnimation = new AppearTextAnimation(_rightText, amountOfFramesPerLineOfText);
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

unittest
{
	import std.math;
	styleOpts = new DefaultStyleOpts;
	auto yakuText = new YakuText("Short text", 10);
	assert(!yakuText.widthOfRightText.isNaN, "The fan text should have a determined width");
	assert(!yakuText.widthOfLeftText.isNaN, "The yaku text should have a determined width.");
}

unittest
{
	class TestStyleOpts : DefaultStyleOpts
	{
		override Vector2i gameScreenSize()
		{
			return Vector2i(1618, 0);
		}
	}
	styleOpts = new TestStyleOpts;
	auto yakuText = new YakuText("Short text", 10);
	yakuText.alignText(200, yakuText.widthOfLeftText, yakuText.widthOfRightText, 1000);
	assert(yakuText._leftText.position.x > 490, "The left position of the yaku text should be larger than its minimal position");
	assert(yakuText._leftText.position.y == 200, "The yaku should be aligned at 200");
	assert(yakuText._rightText.position.x == 1010, "The left position of the fan text should be the splitter plus the margin");
	assert(yakuText._rightText.position.y == 200, "The fan should be aligned at 200");
}

unittest
{
	class TestStyleOpts : DefaultStyleOpts
	{
		override Vector2i gameScreenSize()
		{
			return Vector2i(1618, 0);
		}
	}
	styleOpts = new TestStyleOpts;
	auto yakuText = new YakuText("I am a very long text that should be shortened because of display reasons", 10);
	yakuText.alignText(200, yakuText.widthOfLeftText, yakuText.widthOfRightText, 1000);
	assert(yakuText._leftText.position.x >= 490, "The left position of the yaku text should be larger or equal than its minimal position because the text is shrunk");
	assert(yakuText._leftText.position.y > 200, "Because the yaku is shrinked, the position should be slightyly higher than the top of 200");
	assert(yakuText._rightText.position.x == 1010, "The left position of the fan text should be the splitter plus the margin");
	assert(yakuText._rightText.position.y == 200, "The fan should be aligned at 200");
}

unittest
{
	styleOpts = new DefaultStyleOpts;
	auto yakuText = new YakuText("Short text", 10);
	assert(yakuText._rightText.getColor.a == 0, "The text should be completely faded");
	assert(yakuText._leftText.getColor.a == 0, "The text should be completely faded");
	Animation anime = null;
	foreach(i; 0..10)
	{
		// Also test if the chaining of animations does not give a segfault
		anime = yakuText.chainAnimations(anime);
	}
	while(!anime.done)
	{
		anime.animate;
	}
	assert(yakuText._rightText.getColor.a == 255, "The text should be completely visible");
	assert(yakuText._leftText.getColor.a == 255, "The text should be completely visible");

}