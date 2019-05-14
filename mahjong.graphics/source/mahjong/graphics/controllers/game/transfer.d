module mahjong.graphics.controllers.game.transfer;

import dsfml.graphics;
import mahjong.domain.metagame;
import mahjong.domain.scoring;
import mahjong.engine;
import mahjong.engine.flow.traits;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.drawing.transfer;

class TransferController(TEvent) : ResultController
    if(isSimpleEvent!TEvent)
{
    this(const Metagame metagame, RenderTexture background, 
        TEvent event, Transaction[] transactions, Engine engine)
    {
        super(metagame, background, engine);
        _event = event;
        _transferScreen = new TransferScreen(transactions);
    }

    private TransferScreen _transferScreen;
    private TEvent _event;

    override void draw(RenderTarget target)
    {
        super.draw(target);
        _transferScreen.draw(target);
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
        Controller.instance.substitute(new IdleController(_metagame, _engine));
    }
}
