module mahjong.graphics.drawing.transfer;

import std.conv;
import dsfml.graphics;
import mahjong.domain.player;
import mahjong.engine.scoring;
import mahjong.graphics.anime.animation;
import mahjong.graphics.anime.count;
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
	this(Transaction[] transactions)
	{
		composeTransfers(transactions);
	}

	private void composeTransfers(Transaction[] transactions)
	{
		Transfer[] payingTransfers;
		Transfer[] receivingTransfers;
		foreach(transaction; transactions)
		{
			auto transfer = new Transfer(transaction);
			if(transaction.isPayment)
			{
				moveTransferToTheLeft(transfer);
				payingTransfers ~= transfer;
			}
			else
			{
				moveTransferToTheRight(transfer);
				receivingTransfers ~= transfer;
			}
		}
		setVerticalPositions(payingTransfers);
		setVerticalPositions(receivingTransfers);
		_transfers = payingTransfers ~ receivingTransfers;
	}

	private void moveTransferToTheLeft(Transfer payingTransfer)
	{
		payingTransfer.move(Vector2f(innerMargin.x,0));
	}

	private void moveTransferToTheRight(Transfer receivingTransfer)
	{
		moveTransferToTheLeft(receivingTransfer);
		receivingTransfer.move(Vector2f(2*(box.width + marginBetweenTransferElements), 0));
	}

	private void setVerticalPositions(Transfer[] transfers)
	{
		auto totalHeight = transfers.length * box.height + (transfers.length - 1f) * marginBetweenTransferElements;
		auto remainingSpace = styleOpts.gameScreenSize.y - totalHeight;
		auto offset = remainingSpace/2f;
		foreach(transfer; transfers)
		{
			transfer.move(Vector2f(0, offset));
			offset += box.height + marginBetweenTransferElements;
		}
	}

	private Transfer[] _transfers;

	void draw(RenderTarget target)
	{
		foreach(transfer; _transfers)
		{
			transfer.draw(target);
		}
	}
}

private enum marginBetweenTransferElements = 30f;
private FloatRect box()
{
	auto totalSpace = styleOpts.screenSize.toVector2f - innerMargin;
	auto boxSize = (totalSpace.x - marginBetweenTransferElements)/4;
	return FloatRect(0, 0, boxSize, boxSize);
}

private class Transfer
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
		auto right = Vector2f(box.width + marginBetweenTransferElements, 0);
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
		Animation countTransferAnimation = new CountAnimation(_transaction, transaction.amount, 0);
		auto initialScore = transaction.player.score;
		Animation countScoreAnimation = new CountAnimation(_remainingPoints, initialScore, initialScore + transaction.amount);
		_animation = new Chain!ParallelAnimation(appearMoveTextAnimation, [countTransferAnimation, countScoreAnimation]);
	}

	private Text _transaction;
	private Text _remainingPoints;
	private RenderSprite _renderSprite;
	private Animation _animation;

	Animation animation() @property
	{
		return _animation;
	}

	void move(Vector2f movement)
	{
		_renderSprite.move(movement);
	}

	void draw(RenderTarget target)
	{
		_remainingPoints.changeScoreHighlighting;
		target.draw(_renderSprite);
	}
}