import dsfml.graphics;
import dsfml.window;
import std.stdio;
import std.math;
import std.file;
import std.parallelism;
import core.thread;

import mahjong;
import enumlist;
import objects;
import player;
import yakus;
import ai;
import board;
import meta;
import tile_mod;

void gamewindow(RenderWindow window)
{ /*
    This is going to be the main window in which things happen. This is a continuous interrupt of the main menu. The main manu function will still be active. When the game window closes, the main menu will resume.
  */

  auto board = new Board;
  board.setUp(window);
  board.mainLoop;
}

void bamboowindow(RenderWindow window)
{ /*
    This is going to be the main window in which things happen. This is a continuous interrupt of the main menu. The main manu function will still be active. When the game window closes, the main menu will resume.
  */

  auto board = new Board;
  board.setUp(window, GameMode.Bamboo, amountOfPlayers.bamboo);
  board.mainLoop;
}

void chinesewindow(RenderWindow window)
{ /*
    Have a temporary background image!
  */
  auto title = new Text;
  setTitle(title,"Coming soon!"d);

  string bgfile = "res/china_small.png";
  auto BgTexture = new Texture;
  auto Bg        = new Sprite;
  load(BgTexture, Bg, bgfile);
  pix2scale(Bg,width,height);

  while(window.isOpen())
  {

    Event event;
    while (window.pollEvent(event))
    {
       if(event.type == event.EventType.KeyPressed)
       {
          goto end;
        }
       if(event.type == event.EventType.Closed)
       {
           window.close();
       }
    }
   window.clear;
   window.draw(Bg);
   window.draw(title);
   window.display;
   }

   end:
}

void mainmenu(RenderWindow window)
{
  // Set a solid color as the background.
  auto bg = new RectangleShape(Vector2f(width,height));
  bg.fillColor = Color.Green;
  bg.position = Vector2f(0,0);

  auto MenuTitle = new Text;
  setTitle(MenuTitle,"Main menu"d);

  auto menu = new MainMenu;
  enum options {riichi=0, bamboo, eightPlayer, chinese, quit}
  with(menu)
  {
    addOption("Riichi Mahjong"d, riichiFile, IntRect(314,0,2*width,2*height));
    addOption("Bamboo Battle"d,  bambooFile, IntRect(314,0,4*width,4*height));
    addOption("Thunder Thrill"d,  eightPlayerFile, IntRect(100,0,768,768));
    addOption("Simple Mahjong"d, chineseFile, IntRect(314,0,2*width,2*height));
    addOption("Quit"d, quitFile, IntRect(150,0,700,700));

    construct;
    selection.position = options.riichi;
    selectOpt;
  }

  while(window.isOpen())
  {

    Event event;
    while (window.pollEvent(event))
    {
       if(event.type == event.EventType.KeyPressed)
       {
          if(menu.navigate(event.key.code))
          {
             switch(menu.selection.position) 
             {
               case options.riichi:
                 gamewindow(window);
                 break;
               case options.bamboo:
                 bamboowindow(window);
                 break;
               case options.eightPlayer:
                 //TODO
                 break;
               case options.chinese:
                 chinesewindow(window);
                 break;
               case options.quit:
                 window.close();
                 break;
               default:
                 assert(false);
             }
          }
       }
       if(event.type == event.EventType.Closed)
       {
           window.close();
       }
    }
    menu.changeMenuBackground;

    window.clear;    
 
    // Draw stuff here.
    window.draw(bg);
    menu.draw(window);
    window.draw(MenuTitle);
    window.display;
  }

}

void titlescreen(RenderWindow window)
{
  // Set a solid color as the background.
  auto bg = new RectangleShape(Vector2f(width,height));
  bg.fillColor = Color.Green;
  bg.position = Vector2f(0,0);

  // Construct the text-based title.
  auto title = new Text;
  setTitle(title,"Kinjin Mahjong"d); 

  // Load the title image. For now, we will use Kinjin's logo.
  string logofile = "res/logo.png";
  auto logoTexture = new Texture;
  auto logo = new Sprite;
  load(logoTexture, logo, logofile);
  logo.position = Vector2f(0,0); 
  CenterSprite(logo, "both");

  // Gradually make the logo more visible.
  ubyte opacity = 0;

  while(window.isOpen())
  {
    Event event;

    logo.color = Color(255,255,255,opacity); // Start out transparant
   
    while (window.pollEvent(event))
    {
       if(event.type == event.EventType.Closed)
       {
           window.close();
       }
    }
    window.clear;    
 
    // Draw stuff here.
    window.draw(bg);
    window.draw(title);
    window.draw(logo);

    window.display;

    ++opacity;
    if (opacity == 255)
    {  
      break;  
    }
  }
}

void spriteFromImage(ref Texture texture, ref Sprite sprite, Image image, int x, int y, int w, int h)
{
   textureFromImage(texture, image, x, y, w, h);
   texture.setSmooth(true);
   sprite.setTexture(texture);
}

void textureFromImage(ref Texture texture, Image image, int x, int y, int w, int h)
{
   auto range = IntRect(x,y,w,h);
   if(!texture.loadFromImage(image, range))
   {
     writeln("Texture not loaded.");
     load(texture);
   }
   texture.setSmooth(true);
}

/*void load(ref Texture texture, ref Sprite sprite, ref IntRect rect)
{
  sprite.setTexture(texture);
  sprite.textureRect = rect;
}

void load(ref Texture texture, ref Sprite sprite, int x0, int y0, int w, int h)
{
  auto rect = new IntRect;
  rect.left = x0;
  rect.top = y0;
  rect.width = w;
  rect.height = h;
  load(texture, sprite, rect);
}*/

void load(ref Texture texture, ref Sprite sprite, string texturefile,
         uint x0 = 0, uint y0 = 0, uint size_x = 0, uint size_y = 0)
{
  if(size_x * size_y > 0)
  {
    loadTexture(texture, texturefile, x0, y0, size_x, size_y);
  }
  else
  {
    loadTexture(texture, texturefile);
  }
  texture.setSmooth(true);
  sprite.setTexture(texture);
}

bool loadTexture ( ref Texture texture, string texturefile,
         uint x0, uint y0, uint size_x, uint size_y)
in
{
  assert(size_x * size_y > 0);
}
body
{
      if(!texture.loadFromFile(texturefile, IntRect(x0, y0, size_x, size_y))) // If the size is specified, load only that partition.
      {
        writeln("File ", texturefile, " not found or out of bounds.");
        writeln("Swapping in default texture...");
        texture.loadFromFile(defaultTexture);
        return false;
      }
  return true;
}

bool load(T) (ref T texture, string texturefile) 
{
  if(!texture.loadFromFile(texturefile))
  {
     writeln("File ", texturefile, " not found.");
     return false;
  }
  return true;
}
alias loadFont = load!Font;
alias loadTexture = load!Texture;
alias loadImage = load!Image;

void load(ref Texture texture)
{
   load(texture, defaultTexture);
}

/*void center(T) (ref T sprite, string direction, const ref FloatRect box)
{
  center!(T)(sprite, direction, box.left, box.height, box.width, box.height);
}*/

void alignLeft(T) (ref T sprite, const ref FloatRect box)
{
  sprite.position = Vector2f(box.left, box.top);
  center(sprite, "vertical", box.left, box.top, box.width, box.height);
}

void alignTopLeft(T) (ref T sprite, const ref FloatRect box)
{
  sprite.position = Vector2f(box.left, box.top);
}

void center(T) (ref T sprite, string direction, const float x0 = 0, const float h0 = 0, const float w = width, const float h = height)
in
{
  if((direction != "horizontal") && (direction != "vertical") && (direction != "both"))
  {
    throw new Exception("The input should be horizontal, vertical or both. Written like exactly that!");
  }
}
body
{
  FloatRect size = sprite.getGlobalBounds();
  if((direction == "horizontal") || (direction == "both"))
  {
    float xpos = x0 + (w - size.width)/2.;
    sprite.position = Vector2f(xpos,size.top);
    if(direction == "horizontal")
    {
      return; 
    }
  }

  if((direction == "vertical") || (direction == "both"))
  {
    float ypos = h0 + (h - size.height)/2.;
    if(direction =="both")
    {
      size = sprite.getGlobalBounds(); // Correct for the change that is already made.
    }
    sprite.position = Vector2f(size.left,ypos);
  }
}
alias CenterSprite = center!(Sprite);
alias CenterText = center!(Text);

void alignBottom(ref Sprite sprite, FloatRect box)
{
  auto size = sprite.getGlobalBounds();
  sprite.position = Vector2f(box.left, (box.top + box.height - size.height));
  writeln("The top left corner is (", sprite.position.x, ",", sprite.position.y, ").");
  CenterSprite(sprite, "horizontal", box.left, box.top, box.width, box.height);
  writeln("The top left corner is (", sprite.position.x, ",", sprite.position.y, ").");
}

void setTitle(Text title, dstring text)
{
  /*
    Have a function that takes care of a uniform style for all title fields.
  */
  title.setFont(titleFont);
  title.setString(text);
  title.setCharacterSize(48);
  title.setColor(Color.Black);
  title.position = Vector2f(200,20);
  CenterText(title, "horizontal");
}

/*void setMenuOption(Text opt, dstring text, Font fontIt, float ypos=100)
{
  /*
    Have a function that takes care of a uniform style for all menu fields.
  /
  opt.setFont(fontIt);
  opt.setString(text);
  opt.setCharacterSize(32);
  opt.setColor(Color.Black);
  opt.position = Vector2f(200,ypos);
}*/

void pix2scale(ref Sprite sprite, float x, float y = -1)
out
{
  FloatRect size = sprite.getGlobalBounds();
  assert(abs(size.width - x) < 1); 
  if(y > 0)
  {
   assert(abs(size.height - y) < 1); 
  }
}
body
{
  /*
   Given a size of x by y pixels, scale the sprite such that it takes this size.
  */
  FloatRect size = sprite.getGlobalBounds();
  Vector2f scale0 = sprite.scale;
  float scale_x = x/size.width;
  if(y > 0)
  {
    float scale_y = y/size.height;
    sprite.scale = Vector2f(scale0.x * scale_x,scale0.y * scale_y);
  }
  else
  {
    sprite.scale = Vector2f(scale0.x * scale_x,scale0.x * scale_x);
  }
}

void changeOpacity(ref ubyte[] opacities, const int numOpts, const int position)
{
    /*
      Change the opacity of background images for a more or less fluid transition.
    */
    for(int opt = 0; opt < numOpts;++opt)
    {
      if(opt == position)
      {
         if(opacities[opt]+10<256)
         {
           opacities[opt] += 10;
         }
         else
         {
           opacities[opt] = 255;
         }
      }
      else
      {
         if(opacities[opt]-10>0)
         {
           opacities[opt] -= 10;
         }
         else
         {
           opacities[opt] = 0;
         }
      }
    }
}


void correctOutOfBounds(ref int position, ulong bounds)
in
{
   assert(bounds < int.max);
}
out
{
  assert(position >= 0);
  assert(position < bounds);
}
body
{
  if(position < 0)
  {
    position = 0;
  }
  else if(position >= bounds)
  {
    position = cast(int)bounds - 1;
  }
}

void moveToPlayer(ref Vector2f location, const Vector2f movement, const int playLoc)
{
   float[2] loc = [location.x, location.y];
   float[2] mov = [movement.x, movement.y];
   moveToPlayer(loc,mov,playLoc);
   location = Vector2f(loc[0],loc[1]);
}
void moveToPlayer(ref float[2] location, const float[2] movement, const int playLoc)
{
   float theta = 2 * PI - PI/2 * playLoc;

   location[0] += cos(theta) * movement[0] - sin(theta) * movement[1];
   location[1] += sin(theta) * movement[0] + cos(theta) * movement[1];
}

void rotateToPlayer(ref float rotation, const ref int playLoc)
{
   rotation = 0;
   addRotateToPlayer(rotation, playLoc);
}
void rotateToPlayer(ref Sprite sprite, const ref int playLoc)
{
   float rotation = sprite.rotation;
   rotateToPlayer(rotation, playLoc);
   sprite.rotation = rotation;
}
void rotateToPlayer(ref Tile tile, const ref int playLoc)
{
   tile.rotateToPlayer(playLoc);
}

void addRotateToPlayer(ref float rotation, const ref int playLoc)
{
   rotation += (360 - 90 * playLoc) % 360;
}
void addRotateToPlayer(ref Sprite sprite, const ref int playLoc)
{
   float rotation = sprite.rotation;
   addRotateToPlayer(rotation, playLoc);
   sprite.rotation = rotation;
}
void addRotateToPlayer(ref Tile tile, const ref int playLoc)
{
   tile.addRotateToPlayer(playLoc);
}

Vector2f calculatePositionInSquare(const int amountOfTiles, const float undershootInTiles, const int nthTile, const FloatRect sizeOfTile)
{ /*
     This function calculates the position of the nth tile with in the bottom player quadrant. This function assumes that the amountOfTiles tiles form a square with an undershoot in tiles. Please note that it is the responsibility of the caller to ensure that nthTile < amountOfTiles.
     Furthermore, this function assumes an unrotated tile. It returns the draw position of the tile with respect to the center of the board. Unrotated tiles will therefore be displaye next to each other.
  */
  float delta = (amountOfTiles - undershootInTiles)* sizeOfTile.width /2; // Distance from the center to the inner line of the square.
  auto movement = Vector2f(-delta, delta);
  movement.x += sizeOfTile.width * nthTile;
  return movement;
}
void setTileInSquare(ref Tile tile, const int amountOfTiles, const float undershootInTiles, const int nthTile, const int playLoc = 0)
{
   tile.setRotation(0);
   auto pos = CENTER;
   auto movement = calculatePositionInSquare(amountOfTiles, undershootInTiles, nthTile, tile.getGlobalBounds);
   moveToPlayer(pos, movement, playLoc);
   tile.setPosition(pos);
   rotateToPlayer(tile, playLoc);
}









