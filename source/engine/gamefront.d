module mahjong.engine.gamefront;

import std.experimental.logger;
import std.uuid;

import mahjong.domain.enums.game;
import mahjong.domain.metagame;
import mahjong.engine.enums.game;
import mahjong.engine.opts.bambooopts;
import mahjong.engine.opts.defaultopts;
import mahjong.engine.opts.eightplayeropts;
import mahjong.engine.opts.opts;

/++
	GameFront is the front-end of the game engine. The 
	controllers and AI talk to this when they want to
	play the game. Game logic then takes care of the rest.
+/

class GameFront
{
	private this(Metagame metagame, UUID playerId)
	{
		trace("Constructing game front");
		this.metagame = metagame;
		this.playerId = playerId;
	}
	
	Metagame metagame;
	UUID playerId;
	
	void start()
	{
		trace("Starting metagame");
		metagame.beginGame;
	}
	
	void draw()
	{
		if(!isAllowed(Phase.Draw)) return;
		trace("Drawing tile");
		metagame.drawTile;
	}
	
	void claimChi()
	{
		trace("Claiming chi");
	}
	
	void claimPon()
	{
		trace("Claiming pon");
	}
	
	void claimKan()
	{
		trace("Claiming kan");
	}
	
	void ron()
	{
		trace("Ronning");
	}
	
	void tsumo()
	{
		if(!isAllowed(Phase.Discard)) return;
		trace("Tsumo");
	}
	
	void discard(UUID tile)
	{
		if(!isAllowed(Phase.Discard)) return;
		trace("Discarding tile ", tile);
		metagame.discardTile(tile);
	}
	
	bool isTurn()
	{
		return metagame.isTurn(playerId);
	}
	
	private bool isAllowed(Phase phase)
	{
		return isTurn && metagame.isPhase(phase);
	}
}

/++
	ConsoleFront is the front-end of the game selector.
	External users talk to this interface to select what
	games they want to play.
+/
class ConsoleFront
{
	private this()
	{
		trace("Constructing console front");
	}
	
	/++
		Boots the game and initialises it in the most plain form.
	+/
	static ConsoleFront boot()
	{
		info("Booting console.");
		auto consoleFront = new ConsoleFront;
		info("Booted console.");
		return consoleFront;
	}
	
	/++
		
	+/
	GameFront[] setUp(GameMode gameMode)
	{
		info("Booting game with game mode ", gameMode);
		setGameOptions(gameMode);
		auto metagame = new Metagame;
		info("Initialising game");
		metagame.initialise;
		info("Initialised game");
		GameFront[] gameFronts;
		foreach(player; metagame.players)
		{
			gameFronts ~= new GameFront(metagame, player.id);
		}
		info("Booted game");
		return gameFronts;
	}
	
	private void setGameOptions(GameMode gameMode)
	{
		trace("Setting game options");
		final switch(gameMode) with (GameMode)
		{
			case Riichi:
				gameOpts = new DefaultGameOpts;
				break;
			case Bamboo:
				gameOpts = new BambooOpts;
				break;
			case EightPlayer:
				gameOpts = new EightPlayerOpts;
				break;
		}
		trace("Set game opts");
	}
}
