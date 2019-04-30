module mahjong.graphics.drawing.gameend;

import std.algorithm : map, each, min;
import std.conv;
import dsfml.graphics : Sprite, Text, FloatRect, RenderTarget;
import dsfml.system : Vector2f;
import mahjong.domain.metagame;
import mahjong.domain.player;
import mahjong.graphics.cache.font;
import mahjong.graphics.conv : setSize, size;
import mahjong.graphics.drawing.player : getIcon;
import mahjong.graphics.enums.geometry : CenterDirection;
import mahjong.graphics.list;
import mahjong.graphics.manipulation : center, alignTopRight;
import mahjong.graphics.rendersprite;

class GameEndScreen
{
	this(const Metagame metagame, FloatRect box)
	{
		auto itemSize = (box.height - marginBetweenPlayers * (metagame.amountOfPlayers -1)) 
							/ metagame.amountOfPlayers;
		itemSize = min(itemSize, box.height/3);
		auto itemBox = FloatRect(0,0, 2*itemSize, itemSize);
		_list = new List(Vector2f(0,0), marginBetweenPlayers);
		metagame.players.map!(p => createPlayerResultSprite(p, itemBox)).each!(it => _list ~= it);
		_list.center!(CenterDirection.Both)(box);
	}

	private List _list;

	void draw(RenderTarget target)
	{
		target.draw(_list);
	}
}

unittest
{
	// Check no segfaults test.
	import fluent.asserts;
    import mahjong.domain.opts;
    import mahjong.domain.wrappers;
	import mahjong.graphics.drawing.player;
	import mahjong.test.window;
	auto player = new Player();
	player.draw(AmountOfPlayers(4), new RenderSprite(FloatRect()), 0);
	auto metagame = new Metagame([player, player, player, player], new DefaultGameOpts);
	auto screen = new GameEndScreen(metagame, FloatRect(100,200,300,400));
	auto window = new TestWindow;
	screen.draw(window);
	window.drawnObjects.length.should.equal(1).because("the list is drawn as a whole");
}

private immutable float marginBetweenPlayers = 20;

private RenderSprite createPlayerResultSprite(const Player player, FloatRect size)
{
	auto renderSprite = new RenderSprite(size);
	renderSprite.draw(initialiseIcon(size, player));
	renderSprite.draw(initialiseNameAndScore(size, player));
	return renderSprite;
}

private Sprite initialiseIcon(FloatRect box, const Player player)
{
	auto icon = player.getIcon.dup;
	icon.setSize(Vector2f(box.size.x/2, box.size.y));
	icon.position = Vector2f(0,0);
	return icon;
}

private List initialiseNameAndScore(FloatRect size, const Player player)
{
	auto text = new Text(player.name.to!string, infoFont);
	text.alignTopRight(size);
	auto score = new Text(player.score.to!string, infoFont);
	score.alignTopRight(size);
	auto list = new List(Vector2f(0,0), 5);
	list ~= text;
	list ~= score;
	list.center!(CenterDirection.Vertical)(size);
	return list;
}
