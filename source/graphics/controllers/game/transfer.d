module mahjong.graphics.controllers.game.transfer;

import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.engine.flow.mahjong;
import mahjong.engine.scoring;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.transfer;

class TransferController : ResultController
{
    this(RenderWindow window, const Metagame metagame, RenderTexture background, MahjongEvent event)
    {
        super(window, metagame, background);
        _event = event;
        composeTransferScreen;
    }

    private void composeTransferScreen()
    {
        auto transactions = _event.data.toTransactions(_metagame);
        _transferScreen = new TransferScreen(transactions);
    }

    private TransferScreen _transferScreen;
    private MahjongEvent _event;

    override void draw()
    {
        super.draw();
        _transferScreen.draw(_window);
    }

    protected override void advanceScreen()
    {
        if(!_transferScreen.done)
        {
            finishTransfer;
        }
        else
        {
            finishRound;
        }
    }

    private void finishTransfer()
    {
        _transferScreen.forceFinish;
    }

    private void finishRound()
    {
        _event.handle;
        Controller.instance.substitute(new IdleController(_window, _metagame));
    }
}
