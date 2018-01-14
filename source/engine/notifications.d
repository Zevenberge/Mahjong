module mahjong.engine.notifications;

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
	void notify(Notification notification);
}

/// Default implementation of the INotificationService which acts like a black hole.
class NullNotificationService : INotificationService
{
	void notify(Notification notification)
	{
		// Do nothing.
	}
}