module mahjong.graphics.controllers.game.claim;

import std.array;
import dsfml.graphics;
import mahjong.domain;
import mahjong.engine.chi;
import mahjong.engine.flow.claim;
import mahjong.graphics.controllers.game;

class ClaimController : GameController
{
	this(RenderWindow window, Metagame metagame)
	{
		super(window, metagame);
	}
}

private:

class ClaimOptionFactory
{
	this(Player player, Tile discard, Metagame metagame)
	{
		addRonOption(player, discard);
		addKanOption(player, discard);
		addPonOption(player, discard);
		addChiOptions(player, discard, metagame);
		_areThereClaimOptions = !_claimOptions.empty;
		addDefaultOption;
	}

	private void addRonOption(Player player, Tile discard)
	{
		if(player.isRonnable(discard)) _claimOptions ~= new RonClaimOption(player, discard);
	}

	private void addKanOption(Player player, Tile discard)
	{
		if(player.isKannable(discard)) _claimOptions~= new KanClaimOption(player, discard);
	}

	private void addPonOption(Player player, Tile discard)
	{
		if(player.isPonnable(discard)) _claimOptions ~= new PonClaimOption(player, discard);
	}

	private void addChiOptions(Player player, Tile discard, Metagame metagame)
	{
		if(!player.isChiable(discard, metagame)) return;
		auto candidates = determineChiCandidates(player.game.closedHand.tiles, discard);
		foreach(candidate; candidates)
		{
			_claimOptions ~= new ChiClaimOption(player, discard, candidate, metagame);
		}
	}

	private void addDefaultOption()
	{
		_claimOptions ~= new NoClaimOption;
	}

	private ClaimOption[] _claimOptions;

	private bool _areThereClaimOptions;
	bool areThereClaimOptions() @property
	{
		return _areThereClaimOptions;
	}
}

class ClaimOption
{
	abstract ClaimRequest constructRequest();
}

class NoClaimOption : ClaimOption
{
	override ClaimRequest constructRequest() 
	{
		return new NoRequest;
	}
}

class RonClaimOption : ClaimOption
{
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;

	override ClaimRequest constructRequest() 
	{
		return new RonRequest(_player, _discard);
	}
}

class KanClaimOption : ClaimOption
{
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;
	override ClaimRequest constructRequest() 
	{
		return new KanRequest(_player, _discard);
	}
}

class PonClaimOption : ClaimOption
{
	this(Player player, Tile discard)
	{
		_player = player;
		_discard = discard;
	}

	private Player _player;
	private Tile _discard;

	override ClaimRequest constructRequest() 
	{
		return new PonRequest(_player, _discard);
	}
}

class ChiClaimOption : ClaimOption
{
	this(Player player, Tile discard, ChiCandidate chiCandidate, Metagame metagame)
	{
		_player = player;
		_discard = discard;
		_chiCandidate = chiCandidate;
		_metagame = metagame;
	}

	private Player _player;
	private Tile _discard;
	private ChiCandidate _chiCandidate;
	private Metagame _metagame;

	override ClaimRequest constructRequest() 
	{
		return new ChiRequest(_player, _discard, _chiCandidate, _metagame);
	}
}