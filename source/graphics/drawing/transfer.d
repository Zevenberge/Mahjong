module mahjong.graphics.drawing.transfer;

import std.conv;
import dsfml.graphics;
import mahjong.domain.player;
import mahjong.engine.scoring;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.fade;
import mahjong.graphics.anime.movement;
import mahjong.graphics.coords;
import mahjong.graphics.conv;
import mahjong.graphics.drawing.player;
import mahjong.graphics.drawing.result;
import mahjong.graphics.manipulation;
import mahjong.graphics.opts;
import mahjong.graphics.rendersprite;
import mahjong.graphics.text;

class TransferScreen
{

}

private enum marginBetweenTransferElements = 30f;
private FloatRect box()
{
	auto totalSpace = styleOpts.screenSize.toVector2f - innerMargin;
	auto boxSize = (totalSpace.x - marginBetweenTransferElements)/4;
	return FloatRect(0, 0, boxSize, boxSize);
}

class PayingTransfer
{
	this(Transaction transaction)
	{
		initiateDrawables(transaction);
		setAnimation(transaction);
	}

	private void initiateDrawables(Transaction transaction)
	{
		auto icon = composeIcon(transaction.player);
		auto texts = composeTexts(transaction);
		placeTextAndIcon(icon, texts, transaction);
	}

	private Sprite composeIcon(const Player player)
	{
		auto immutableIcon = player.getIcon;
		auto icon = immutableIcon.dup;
		icon.setSize(box.size);
		return icon;
	}

	private RenderSprite composeTexts(Transaction transaction)
	{
		auto transactionText = composeTransactionText(transaction);
		auto remainingPointsText = composeRemainingPoints(transaction.player);
		auto renderSprite = new RenderSprite(box);
		renderSprite.draw(transactionText);
		renderSprite.draw(remainingPointsText);
		return renderSprite;
	}

	private Text composeTransactionText(Transaction transaction)
	{
		auto transactionText = TextFactory.resultText;
		if(transaction.isPayment)
		{
			transactionText.setString(transaction.amount.to!string);
		}
		else
		{
			transactionText.setString("0");
		}
		transactionText.alignRight(box);
		_transaction = transactionText;
		return transactionText;
	}

	private Text composeRemainingPoints(const Player player)
	{
		auto points = player.score;
		auto remainingPoints = TextFactory.resultText;
		remainingPoints.setString(points.to!string);
		remainingPoints.alignRight(box);
		_remainingPoints = remainingPoints;
		return remainingPoints;
	}

	private void placeTextAndIcon(Sprite icon, RenderSprite text, Transaction transaction)
	{
		auto right = Vector2f(box.width, 0);
		if(transaction.isPayment)
		{
			text.position = right;
		}
		else
		{
			icon.position = right;
		}
	}

	private void setAnimation(Transaction transaction)
	{
		Animation appearAnimation = new AppearTextAnimation(_transaction, 90);
		auto finalCoords = _transaction.getFloatCoords;
		finalCoords.move(Vector2f(0, -50));
		Animation movementAnimation = new MovementAnimation(_transaction, finalCoords, 90);
		Animation appearMoveTextAnimation = new ParallelAnimation([appearAnimation, movementAnimation]);

		_animation = appearMoveTextAnimation;
	}

	private Text _transaction;
	private Text _remainingPoints;
	private RenderSprite _renderSprite;
	private Animation _animation;

	Animation animation() @property
	{
		return _animation;
	}

	Vector2f position(Vector2f newPosition) @property
	{
		return _renderSprite.position = newPosition;
	}

	void draw(RenderTarget target)
	{
		_remainingPoints.changeScoreHighlighting;
		target.draw(_renderSprite);
	}
}