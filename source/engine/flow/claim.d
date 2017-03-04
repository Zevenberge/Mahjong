module mahjong.engine.flow.claim;

import std.algorithm;
import std.array;
import std.experimental.logger;
import mahjong.domain;
import mahjong.engine.flow;

class ClaimFlow : Flow
{
	this(Tile tile, Metagame game)
	{
		trace("Constructing claim flow");
		super(game);
		_tile = tile;
		initialiseClaimEvents;
	}

	override void advanceIfDone()
	{
		if(done) branch;
	}
		
	private:
		const Tile _tile;
		ClaimEvent[] _claimEvents;

		void initialiseClaimEvents()
		{
			_claimEvents = metagame.otherPlayers
						.map!(p => createEventAndNotifyHandler(p))
						.array;
		}

		ClaimEvent createEventAndNotifyHandler(Player player)
		{
			auto event = new ClaimEvent(_tile, player);
			player.eventHandler.handle(event);
			return event;
		}

		bool done() @property pure const
		{
			return _claimEvents.all!(ce => ce.isHandled);
		}

		void branch()
		{
			switchFlow(new TurnEndFlow(metagame));
		}
}

class ClaimEvent
{
	this(const Tile tile, Player player)
	{
		this.tile = tile;
	}
	const Tile tile;
	private ClaimRequest _claimRequest;

	void handle(ClaimRequest claimRequest)
	in
	{
		assert(claimRequest !is null, "When handling the claim event, the request should not be null");
	}
	body
	{
		_claimRequest = claimRequest;
	}

	bool isHandled() @property pure const
	{
		return _claimRequest !is null;
	}
}

enum Request {None, Chi, Pon, Kan, Ron}

interface ClaimRequest
{
	void apply(Metagame metagame);
	bool isAllowed(Metagame metagame);
	@property Request request() pure const;
}

class NoRequest : ClaimRequest
{
	void apply(Metagame metagame)
	{
		// Do nothing.
	}

	bool isAllowed(Metagame metagame)
	{
		return true;
	}

	Request request() @property pure const
	{
		return Request.None;
	}
}

class PonRequest : ClaimRequest
{
	void apply(Metagame metagame)
	{
		// Do nothing.
	}

	bool isAllowed(Metagame metagame)
	{
		return false;
	}

	Request request() @property pure const
	{
		return Request.Pon;
	}
}

class KanRequest : ClaimRequest
{
	void apply(Metagame metagame)
	{
		// Do nothing.
	}

	bool isAllowed(Metagame metagame)
	{
		return false;
	}

	Request request() @property pure const
	{
		return Request.Kan;
	}
}

class ChiRequest : ClaimRequest
{
	void apply(Metagame metagame)
	{
		// Do nothing.
	}

	bool isAllowed(Metagame metagame)
	{
		return false;
	}

	Request request() @property pure const
	{
		return Request.Chi;
	}
}

class RonRequest : ClaimRequest
{
	void apply(Metagame metagame)
	{
		// Do nothing.
	}

	bool isAllowed(Metagame metagame)
	{
		return false;
	}

	Request request() @property pure const
	{
		return Request.Ron;
	}
}