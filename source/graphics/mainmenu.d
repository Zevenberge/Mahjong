module mahjong.graphics.mainmenu;

import std.conv;

import dsfml.graphics.color;
import dsfml.graphics.rect;
import dsfml.graphics.renderwindow;
import dsfml.graphics.sprite;
import dsfml.graphics.texture;
import mahjong.graphics.enums.geometry;;
import mahjong.graphics.graphics;
import mahjong.graphics.menu;

class MainMenu : Menu
{
   Sprite[] optSprites;
   Texture[] optTextures;
   ubyte[] opacities;
   
   void addOption(dstring text, string filename, IntRect range)
   { // Add an option to the menu and do all bureaucratic bullshit.
     auto texture = new Texture;
     auto sprite = new Sprite;
     load(texture, sprite, filename, range.left, range.top, range.width, range.height);
     pix2scale(sprite, width, height);
     optSprites ~= sprite;
     optTextures ~= texture;
     super.addOption(text);
     opacities ~= 0;
   }

   void changeMenuBackground()
   {
      selectOpt;
      changeOpacity;
      applyColors;
   }
   void changeOpacity()
   {
     .changeOpacity(opacities, to!int(opts.length), selection.position);
   }
   void applyColors()
   {
      for(int i = 0; i < opts.length; ++i)
      {
        optSprites[i].color = Color(255,255,255,opacities[i]);
      }
   }

  /*
     Draw functions.
  */
   void drawBg(ref RenderWindow window)
   {
     foreach(bgImg; optSprites)
     {
       window.draw(bgImg);
     }
   }
   override void draw(ref RenderWindow window)
   {
      drawBg(window);
      super.draw(window);
   }
}
