module mahjong.graphics.popup.service;

import std.experimental.logger;
import dsfml.graphics : RenderTarget;
import mahjong.domain.player;
import mahjong.engine.notifications;
import mahjong.graphics.controllers.controller;
import mahjong.graphics.controllers.game;
import mahjong.graphics.popup.popup;
import mahjong.graphics.i18n;

class PopupService : INotificationService
{
    mixin Notify!(Notification, const Player);
    mixin Notify!(Notification);

    private mixin template Notify(Args...)
    {
        final void notify(Args args)
        {
            info("Notifying about ", args[0]);
            auto popup = createPopup(args);
            Controller.instance.add(popup);
        }
    }
}

@("If I notify about a player popup, the controller has a player popup")
unittest
{
    import fluent.asserts;
    import mahjong.domain.wrappers;
    import mahjong.graphics.anime.animation;
    import mahjong.graphics.drawing.player;
    setDefaultTestController;
    scope(exit) setDefaultTestController;
    scope(exit) clearAllAnimations;
    import std.typecons : BlackHole;
    scope(exit) clearPlayerCache;
    auto renderTarget = new BlackHole!RenderTarget;
    auto service = new PopupService;
    auto player = new Player();
    player.draw(AmountOfPlayers(2), renderTarget, 0f);
    service.notify(Notification.Chi, player);
    Controller.instance.has!PlayerPopup.should.equal(true);
}

@("If I notify about a general game popup, the controller has a game popup")
unittest
{
    import fluent.asserts;
    import mahjong.graphics.anime.animation;
    setDefaultTestController;
    scope(exit) setDefaultTestController;
    scope(exit) clearAllAnimations;
    auto service = new PopupService;
    service.notify(Notification.ExhaustiveDraw);
    Controller.instance.has!GamePopup.should.equal(true);
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