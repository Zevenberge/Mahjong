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
	void notify(Notification notification, const Player notifyingPlayer);
}

import std.typecons;
alias NullNotificationService = BlackHole!INotificationService;
