module mahjong.engine.notifications;

import mahjong.domain.player;

enum Notification
{
    Chi,
    Pon,
    Kan,
    Ron,
    Tsumo,
    ExhaustiveDraw,
    AbortiveDraw,
    Riichi
}

interface INotificationService
{
    /// Notify that a single player shouts something.
    void notify(Notification notification, const Player notifyingPlayer);
    /// Notify about a game-wide notification
    void notify(Notification notification);
}

import std.typecons;
alias NullNotificationService = BlackHole!INotificationService;
