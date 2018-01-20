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

/// Default implementation of the INotificationService which acts like a black hole.
class NullNotificationService : INotificationService
{
	void notify(Notification notification, const Player notifyingPlayer)
	{
		// Do nothing.
	}
}