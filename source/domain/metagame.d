module mahjong.domain.metagame;

import std.experimental.logger;
import std.string;
import std.random;
import std.conv;
import dsfml.graphics;

import mahjong.domain.enums.game;
import mahjong.domain.enums.tile;
import mahjong.domain.enums.wall;
import mahjong.domain.player;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.ai;
import mahjong.graphics.drawing.player;
import mahjong.engine.enums.game;
import mahjong.engine.mahjong;
import mahjong.engine.opts.opts;
import mahjong.graphics.enums.game;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.kanji;
import mahjong.graphics.enums.resources;
import mahjong.graphics.graphics;

class Metagame
{
   /*
     Preparation of the game.
   */

   int gameMode = GameMode.Riichi;
   Player[] players; //The droids playing
   Wall wall;
   int deadWallLength = .deadWallLength;

   Texture tilesTexture;

   @property setMode(const int gameMode)
   {
   		trace("Setting the game mode.");
      this.gameMode = gameMode;
      setDeadWallLength();
   }
   
   @property setDeadWallLength()
   {
      switch(gameMode)
      {
         case(GameMode.Bamboo):
            this.deadWallLength = .bambooDeadWall;
            break;
         default:
            this.deadWallLength = .deadWallLength;
            break;
      }
   }

   void nextRound()
   {
   		info("Moving to the next round");
     setPlayers(players[playerLocation.bottom].getWind);
   }
   void setPlayers(int initialWind)
   {
   		info("Setting up the game");
     setPlayersGame(initialWind);
     	trace("Setting up the wall.");
     wall.reset();
     distributeTiles;
     firstTurn;
     status = Status.newGame;
   }
   private void setPlayersGame(int initialWind)
   {
     foreach(player; players) // Re-initialise the players' game.
     { 
       player.firstGame(initialWind % gameOpts.amountOfPlayers);
       ++initialWind;
     }
   }

   void reset()
   { 
     wall = new Wall();
     int initialWind = uniform(0, gameOpts.amountOfPlayers); 
     setPlayers(initialWind);
   }

   void setTilesTexture()
   {
     tilesTexture = new Texture;
     loadTexture(tilesTexture, tilesFile);
     reset();
   }

   void constructPlayers(ref Texture stickTexture)
   { // FIXME: Encapsulate this in the player class.
     for(int i=0; i < gameOpts.amountOfPlayers;++i)
      {
      // TODO: Idea: Make a number of preset profiles that can be loaded. E.g. player1avatar = Sakura.avatar;
        trace("Constructing player ", i);
        auto player = new Player;
        player.playLoc = (this.gameMode == GameMode.Bamboo ) ? 2*i : i;
        trace(player.name);
        players ~= player;
      }
   }

   void distributeTiles()
   {
     for(int i = 0; i < 12/tilesAtOnce; ++i)
     {
       distributeXTiles(tilesAtOnce);
     }
     distributeXTiles(1);
   }
   private void distributeXTiles(int amountOfTiles)
   {
       foreach(player; players)
       { // TODO: update such that distribution begins with East.
         for(int i = 0; i < amountOfTiles; ++i)
         {
            player.drawTile(wall);
         }
       }
   }

   /*
     The game itself.
   */

   private int Turn = 0; // Whose turn it is.
   private int status = Status.newGame;
   private bool pause = false; //FIXME: make the metagame independent of the pause function

   private enum Phase {draw, select, discard, end}
   private int phase = Phase.draw;
   private Tile discard;

   private void firstTurn() // Start at East.
   {
     int i;
     foreach(player; players)
     {
       if(player.game.wind == Winds.east)
       {
         Turn = i;
         phase = Phase.draw;
         break;
       }
       ++i;
     }
   }

   public void gameLoop()
   {
     startGame;
     if(status == Status.running)
     {
       endPhase;
       discardPhase;
       selectPhase;
       drawPhase;
     }
   }

   private void startGame()
   {
     if(status == Status.newGame)
     {
       // TODO: add shiny effects to display that the game is starting.
       info("Starting new game...");
       info("Good luck!");
       status = Status.running;
     }
   }

   private void drawPhase()
   {
     if(phase == Phase.draw)
     {
       draw;
       checkMahjong;
       phase = Phase.select;
     }
   }

   private void draw()
   { // Not to be confused wit the graphical drawing.
     players[Turn].drawTile(wall);
     if(Turn == playerLocation.bottom)
        players[Turn].showHand;
   }

   private void checkMahjong()
   {
     if((status == Status.running) && (status != Status.mahjong) && scanHand)
     { // TODO: Make this function actually do something.
       flipOverWinningTiles();
       info("Congratz!");
       status = Status.mahjong;
     }
   }

   private void selectPhase()
   { // Only for the AI. If the human player needs to select, this is done via event input.
     if((phase == Phase.select) && (Turn != playerLocation.bottom))
     {
       activateAI;
       phase = Phase.discard;
     }
   }

   private void activateAI()
   {
     // If it is not the human player's turn and the game is running, activate the AI.
     if((status == Status.running) && (Turn != playerLocation.bottom))
     {// FIXME: Make the AI functions static calculations!
       auto ai = new aiRandom;
       discard = ai.Discard(players[Turn].game.closedHand.tiles);
     }
     // TODO: make profiles embedded in the player class with AI objects in them.
   }

   private void discardPhase()
   {
     if(phase == Phase.discard)
     {
       discardTile(discard);
       discard = null;
       phase = Phase.end;
     }
   }

   int[] discardTile(T) (T discard)
   {
     players[Turn].discard(discard);
     return isPonnable(players[Turn].getLastDiscard);
   }

   private void endPhase()
   {  //FIXME: should not be called when there is a claimable tile.
     if(phase == Phase.end)
     {
       if(advanceTurn)
       {
         phase = Phase.draw;
       }
     }
   }

   bool advanceTurn()
   {
     if(wall.length > deadWallLength)
     {
       nextTurn();
       return true;
     }
     else
     {
       exhaustiveDraw;
       return false;
     }
   }

   void nextTurn()
   {
     ++Turn;
     Turn = Turn % gameOpts.amountOfPlayers;
   }

   /*
      Group everything that has interaction with the player.
   */

   public void checkGameButtons(const ref Event event)
   {
     if(players[playerLocation.bottom].game.closedHand.navigate(event.key.code))
     {
       if((status == Status.running) && (Turn == playerLocation.bottom))
       {
         discard = players[playerLocation.bottom].game.closedHand.tiles[players[playerLocation.bottom].game.closedHand.selection.position];
         phase = Phase.discard;
       }
     }
   }

   private void exhaustiveDraw()
   {
     status = Status.exhaustiveDraw;
     checkNagashiMangan;
     checkTenpai;
   }
   private void checkNagashiMangan()
   {
     foreach(player; players)
     {
       if(player.isNagashiMangan)
       {
         // Go ro results screen.
         status = Status.mahjong;
         info("Nagashi Mangan!");
       }
     }
   }
   private void checkTenpai()
   {
     foreach(player; players)
     {
       if(player.isTenpai)
       {
         player.showHand;
         info(cast(Kanji)player.getWind, " is tenpai!");
       }
       else
       {
         player.closeHand;
       }
     }
   }


   /*
     Subroutines regarding the drawing of the window.
   */

   public void drawGame(ref RenderWindow window)
   {
     drawWall(window);
     drawPlayers(window);
   }

   private void drawWall(ref RenderWindow window)
   {
     wall.draw(window);
   }

   private void drawPlayers(ref RenderWindow window)
   {
     drawSelections(window);
     foreach(player;players)
     {
       player.draw(window);
     }
   }
   private void drawSelections(ref RenderWindow window)
   { // TODO: Encapsulate this.
     if((status == Status.running) && !claimable)
     {
       window.draw(players[playerLocation.bottom].game.closedHand.selection.visual);
     }

     if((status == Status.running) && (playerLocation.bottom.isIn(canClaimTile)))
     {
       players[playerLocation.bottom].game.openHand.drawSelections(window);
     }
   }  

   /*
     Random useful functions.
   */

   private bool scanHand()
   {
     return players[Turn].isMahjong;
   }
/*
   bool requirePlayerInteraction()
   { //FIXME: Either implement this or throw it away.
      bool interaction = false;
      if((Turn == playerLocation.bottom) && !claimable) // If it is the players turn and noone is claiming a tile. 
      {
         interaction = true;
         return interaction;
      }
      if((Turn != playerLocation.bottom) && claimable)
      {
         if(canClaimTile == playerLocation.bottom) // If the player can claim a tile.
         {
           interaction = true;
         }
      }
      return interaction;
   }
*/
   private void flipOverWinningTiles()
   {
     foreach(player; players)
     {
       if(player.isMahjong)
          player.showHand;
       else
          player.closeHand; 
     }
   }

   /*
      Dump everything related to claiming tiles here.
   */ 

   private bool _ponnable = false;
   private bool _chiable = false;
   private bool _kannable = false;
   private bool _ronnable = false;

   bool ponnable() { return _ponnable; }
   bool chiable() { return _chiable; }
   bool kannable() { return _kannable; }
   bool ronnable() { return _ronnable; }

   private int[] canClaimTile = [-1]; // The playerLocations that can claim a tile.

   private bool claimable()
   {
     return ponnable || chiable || kannable || ronnable;
   }
   private int[] isPonnable(const Tile discard)
   { /*
        Checks whether a discard can be ponned and returns the player location (.bottom, .right, .etc). If the tile cannot be ponned, it returns a -1.
     */
     // Start checking for pons at next player.
     for(int i = Turn+1; i < Turn + gameOpts.amountOfPlayers; ++i)
     {
        if(players[i % gameOpts.amountOfPlayers].isPonnable(discard))
        {
          trace(cast(playerLocation)(i % gameOpts.amountOfPlayers), " could have ponned that one.");
          break;
        }
     }
     canClaimTile = [-1];
     return canClaimTile;
   } 

   private int[] isRonnable(Tile discard)
   { /*
       Checks whether the discard can be ronned by any player.
     */
     // Start checking for rons at the next player.
     _ronnable = false;
     canClaimTile = [];
     for(int i = Turn + 1; i < Turn + gameOpts.amountOfPlayers; ++i)
     {
        int pl = i % gameOpts.amountOfPlayers;
        if(players[pl].isRonnable(discard))
        {
           _ronnable = true;
           canClaimTile ~= pl;
           trace(cast(playerLocation) pl , "can ron it!"); 
        }
     }

     if(!_ronnable)
        canClaimTile = [-1];
     return canClaimTile;
   } 
}
