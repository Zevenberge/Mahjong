module meta;

import std.stdio;
import std.string;
import std.random;
import std.conv;

import enumlist;
import graphics;
import mahjong;
import ai;
import objects;
import player;
import tile_mod;
import wall;

import dsfml.graphics;

class Metagame
{
   /*
     Preparation of the game.
   */

   int AmountOfPlayers = amountOfPlayers.normal;
   int gameMode = GameMode.Riichi;
   Player[] players; //The droids playing
   Wall wall;
   int deadWallLength = .deadWallLength;

   Texture tilesTexture;

   @property setMode(const int gameMode)
   {
      this.gameMode = gameMode;
      setDeadWallLength();
   }
   @property setAmountOfPlayers(const int aop)
   {
      this.AmountOfPlayers = aop;
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
     setPlayers(players[playerLocation.bottom].getWind);
   }
   void setPlayers(int initialWind)
   {
     setPlayersGame(initialWind);
     wall.reset();
     distributeTiles;
     firstTurn;
     status = Status.newGame;
   }
   private void setPlayersGame(int initialWind)
   {
     foreach(player; players) // Re-initialise the players' game.
     { 
       player.firstGame(initialWind % AmountOfPlayers);
       ++initialWind;
     }
   }

   void reset()
   { 
     wall = new Wall(gameMode, tilesTexture);
     int initialWind = uniform(0, AmountOfPlayers); 
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
     for(int i=0; i < AmountOfPlayers;++i)
      {
      // TODO: Idea: Make a number of preset profiles that can be loaded. E.g. player1avatar = Sakura.avatar;
        writeln("Constructing player ", i);
        auto player = new Player;
        player.playLoc = (this.gameMode == GameMode.Bamboo ) ? 2*i : i;
        player.loadIcon(defaultTexture);
        player.placeIcon();
        player.loadPointsBg(stickTexture);
        player.placePointsBg();
        player.loadPointsDisplay();
        player.loadWindsDisplay();
        player.updatePoints();
        writeln(player.name);
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
       if(player.game.location == winds.east)
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
       writeln("Starting new game...");
       writeln("Good luck!");
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
       writeln("Congratz!");
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
     Turn = Turn % AmountOfPlayers;
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
         writeln("Nagashi Mangan!");
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
         writeln(cast(kanji)player.getWind, " is tenpai!");
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
       player.drawWindow(window);
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
     for(int i = Turn+1; i < Turn + AmountOfPlayers; ++i)
     {
        if(players[i % AmountOfPlayers].isPonnable(discard))
        {
          writeln(cast(playerLocation)(i % AmountOfPlayers), " could have ponned that one.");
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
     for(int i = Turn + 1; i < Turn + AmountOfPlayers; ++i)
     {
        int pl = i % AmountOfPlayers;
        if(players[pl].isRonnable(discard))
        {
           _ronnable = true;
           canClaimTile ~= pl;
           writeln(cast(playerLocation) pl , "can ron it!"); 
        }
     }

     if(!_ronnable)
        canClaimTile = [-1];
     return canClaimTile;
   } 
}
