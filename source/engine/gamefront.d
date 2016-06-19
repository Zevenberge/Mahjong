module mahjong.engine.gamefront;

import std.algorithm.iteration;
import std.experimental.logger;
import std.signals;
import std.uuid;

import mahjong.domain.enums.game;
import mahjong.domain.metagame;
import mahjong.domain.player;
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
		metagame.connect(&gameStarted);
		this.playerId = playerId;
	}
	
	Metagame metagame;
	UUID playerId;
	
	void start()
	{
		if(metagame.hasStarted) return;
		trace("Starting metagame");
		metagame.beginGame;
	}
	
	void draw()
	{
		if(!isAllowed(Interaction.Draw)) return;
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
		if(!isAllowed(Interaction.Discard)) return;
		trace("Tsumo");
	}
	
	void discard(UUID tile)
	{
		if(!isAllowed(Interaction.Discard)) return;
		trace("Discarding tile ", tile);
		metagame.discardTile(tile);
	}
	
	bool isTurn()
	{
		return metagame.isTurn(playerId);
	}
	
	bool isRunning()
	{
		return metagame.status == Status.Running;
	}
	
	Interaction requiredInteraction()
	{
		if(!isTurn || !isRunning)
		{
			return Interaction.None;
		}
		switch(metagame.phase) with(Phase)
		{
			case Draw:
				return Interaction.Draw;
			case Discard:
				return Interaction.Discard;
			default:
				return Interaction.None;
		}
	}
	
	private bool isAllowed(Interaction action)
	{
		return action == requiredInteraction;
	}
	Player owningPlayer()
	{
		return metagame.players.filter!(p => p.id == playerId).front;
	}
	
	mixin Signal!Player;
	private void gameStarted()
	{
		trace("Game started");
		emit(owningPlayer);
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
		Sets up the game given the game mode. Afterwards, the returned GameFronts should
		not be bothered by the what game mode they are in.	
	+/
	GameFront[] setUp(GameMode gameMode)
	{
		info("Booting game with game mode ", gameMode);
		auto metagame = setGameOptions(gameMode);
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
	
	private Metagame setGameOptions(GameMode gameMode)
	{
		trace("Setting game options");
		final switch(gameMode) with (GameMode)
		{
			case Riichi:
				gameOpts = new DefaultGameOpts;
				return new Metagame;
			case Bamboo:
				gameOpts = new BambooOpts;
				return new BambooMetagame;
			case EightPlayer:
				gameOpts = new EightPlayerOpts;
				return new EightPlayerMetagame;
		}
	}
}
