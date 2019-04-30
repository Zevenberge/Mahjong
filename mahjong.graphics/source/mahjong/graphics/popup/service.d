module mahjong.graphics.popup.service;

import std.experimental.logger;
import dsfml.graphics : RenderTarget;
import mahjong.domain.player;
import mahjong.engine.notifications;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.popup.popup;
import mahjong.graphics.i18n;
import mahjong.util.range : remove;

class PopupService : INotificationService
{
    mixin Notify!(Notification, const Player);
    mixin Notify!(Notification);

    private mixin template Notify(Args...)
    {
        void notify(Args args)
        {
            info("Notifying about ", args[0]);
            auto popup = createPopup(args);
            auto gameController = cast(GameController)Controller.instance;
            if(gameController){
                Controller.instance.substitute(new PopupController(gameController, popup));
            }
        }
    }
}

private Popup createPopup(Notification notification, const Player player)
{
    auto msg = notification.translate;
    return new PlayerPopup(msg, player);
}

private Popup createPopup(Notification notification)
{
    auto msg = notification.translate;
    return new GamePopup(msg);
}