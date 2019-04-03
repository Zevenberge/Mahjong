module mahjong.graphics.drawing.game.sticks;

import std.conv;
import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.graphics.cache.font;
import mahjong.graphics.cache.texture;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;

package void drawCounter(const Metagame game, RenderTarget target)
{
    drawSticks(counterSprite, game.counters, target);
}

package void drawRiichiSticks(const Metagame game, RenderTarget target)
{
    drawSticks(riichiSprite, game.amountOfRiichiSticksAtTheBeginningOfTheRound, target);
}

private void drawSticks(Sprite sprite, size_t amount, RenderTarget target)
{
    if(amount == 0) return;
    target.draw(sprite);
    if(amount > 1)
    {
        auto text = new Text;
        text.setColor = Color.Black;
        text.setString = "x" ~ amount.to!string;
        text.setFont = infoFont;
        text.setCharacterSize = 10;
        text.alignRight(sprite.getGlobalBounds);
        target.draw(text);
    }
}

package void clearSprites()
{
    _counterSprite = null;
    _riichiSprite = null;
}

private Sprite _counterSprite;
private Sprite counterSprite() @property
{
    if(!_counterSprite)
    {
        _counterSprite = new Sprite(stickTexture);
        _counterSprite.textureRect = hundredYenStick;
        _counterSprite.scale = Vector2f(0.5, 0.5);
        drawingOpts.placeCounter(_counterSprite);
    }
    return _counterSprite;
}

private Sprite _riichiSprite; 
private Sprite riichiSprite() @property
{
    if(!_riichiSprite)
    {
        _riichiSprite = new Sprite(stickTexture);
        _riichiSprite.textureRect = thousandYenStick;
        _riichiSprite.scale = Vector2f(0.5, 0.5);
        drawingOpts.placeRiichiStick(_riichiSprite);
    }
    return _riichiSprite;
}