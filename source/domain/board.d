module mahjong.domain.board;

import std.experimental.logger;

import mahjong.domain.enums.game;
import mahjong.domain.metagame;
import mahjong.engine.mahjong;
import mahjong.engine.ai;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.graphics;
import mahjong.graphics.menu;

import dsfml.graphics;

class Board
{
  /*
     Set up general variables.
  */

  private Texture tableTexture;
  private Sprite tableSprite;
  alias Table = tableSprite;
  private Image sticksImg;
  private Texture blankStickTexture;
  Metagame meta;

  bool checkSprite()
  { // See whether the sprite is initialised.
    return !(tableSprite is null);
  }

  bool checkTexture()
  { // See whether the texture is initialised.
    return !(tableTexture is null);
  }

  void setSticksImg()
  {
    sticksImg = new Image;
    loadImage(sticksImg, sticksFile);
  }

  void setBlankStick()
  {
    blankStickTexture = new Texture;
    textureFromImage(blankStickTexture, sticksImg, stick.left, stick.top, stick.width, stick.height);
  }

  void setTable()
  {
    tableTexture = new Texture;
    tableSprite = new Sprite;
    load(tableTexture, tableSprite, tableFile);
    pix2scale(tableSprite, width, height);
  }

  void renderBg()
  { /*
     Draw only the background and remove everything else.
    */
    window.clear;
    window.draw(tableSprite);
    window.display;
  }

  void setUp(ref RenderWindow window, const int gameMode = GameMode.Riichi, const int AmountOfPlayers = amountOfPlayers.normal)
  {
    setTable;
    setSticksImg;
    setBlankStick;
    this.window = window;
    renderBg;
    meta = new Metagame;
	trace("Created the metagame.");
    meta.setMode(gameMode);
	trace("Set the game mode.");
    meta.setAmountOfPlayers(AmountOfPlayers);
	trace("Set the amount of players");
    meta.constructPlayers(blankStickTexture);
	trace("Constructed the players.");
    meta.setTilesTexture;
	trace("Set the tiles texture.");
    setPauseMenu;
	trace("Constructed the pause menu.");
  }

  /*
    Set up the pause menu and associated functions.
  */

  private Menu pauseMenu;
  private bool pause = true;
  private RectangleShape haze;

  enum pauseOpt {Continue = 0, NewGame, Quit}
  void setPauseMenu()
  {
    pauseMenu = new Menu;
    pauseMenu.addOption("Continue"d);
    pauseMenu.addOption("New Game"d);
    pauseMenu.addOption("Quit"d);
    initialisePauseMenu;
    initialiseHaze;
  }
  void initialisePauseMenu()
  {
    pauseMenu.construct;
    pauseMenu.selection.position = pauseOpt.Continue;
    pauseMenu.selectOpt;
  }

  void initialiseHaze()
  {
    haze = new RectangleShape(Vector2f(width, height));
    haze.fillColor = Color(126,126,126,126);
  }

  /*
     In the main loop, check all interactions.
  */
  private RenderWindow window;
  private bool Continue = true;
  public void mainLoop(ref RenderWindow window)
  {
    this.window = window;
    mainLoop;
  }
  public void mainLoop()
  {
    while(this.window.isOpen && Continue)
    {
      if(!pause)
      {
        meta.gameLoop;
      }
      checkEvents;
      displayWindow;
    }
  }

  /*
     Check the events and react to them.
  */
  private void checkEvents()
  {
     Event event;
     while(window.pollEvent(event))
     {
       if(event.type == event.EventType.KeyPressed)
       {
         checkButtons(event);
       }
       if(event.type == event.EventType.MouseMoved)
       {
         checkMouseMovement(event);
       }
       if(event.type == event.EventType.MouseButtonReleased)
       {  // For convinience, only react if the mouse button is released. A misclick can be prevented by holding the mouse button.
         checkClick(event);
       }
       if(event.type == event.EventType.Closed)
       {
         window.close;
       }
     }
  }
  private void checkButtons(const ref Event event)
  {
    checkGeneralButtons(event);
    if(pause)
    {
      checkPauseButtons(event);
    }
    else
    {
      checkGameButtons(event);
    }
  }
  private void checkMouseMovement(const ref Event event)
  {
    // TODO: Implement that moving across selectables selects the opt under the cursor.
  }
  private void checkClick(const ref Event event)
  {  //TODO: Implement clicks -> discards and clicks -> enter options.
    trace("Clickerty click.");
  }
  private void checkGeneralButtons(const ref Event event)
  {
    switch(event.key.code)
    {
      case Keyboard.Key.Escape:
        toggle(pause);
        break;
      default:
        break;
    }
  }
  void checkPauseButtons(const ref Event event)
  {
    if(pauseMenu.navigate(event.key.code))
    {
      switch(pauseMenu.selection.position)
      {
        case pauseOpt.Continue:
         toggle(pause);
         break;
        case pauseOpt.NewGame:
         meta.reset;
         toggle(pause);
         break;
        case pauseOpt.Quit:
         Continue = false;
         break;
        default:
         assert(false);
      }
    }
  }
  void checkGameButtons(const ref Event event)
  {
    meta.checkGameButtons(event);
  }

  /*
   Group all the functions that help draw the window.
  */
  private void displayWindow()
  {
    window.clear;
    drawWindow;
    window.display;
  }
  private void drawWindow()
  {
    drawBg;
    drawGame;
    drawPause;
  }
  private void drawBg()
  {
    window.draw(Table);
  }
  private void drawGame()
  {
    meta.drawGame(window);
  }
  private void drawPause()
  {
    if(pause)
    {
      window.draw(haze);
      window.draw(pauseMenu.selection.visual);
      foreach(opt; pauseMenu.opts)
      {
        window.draw(opt);
      }
    }
  }

}
