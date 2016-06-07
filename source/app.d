module main;

import dsfml.graphics;
import dsfml.window;
import std.stdio;
import std.file;

import mahjong.engine.mahjong;
import mahjong.engine.yaku;
import mahjong.graphics.cache.font;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.graphics;


void main(string[] args)
{ 
  // Load different fonts so that we do not need to load them every screen.. 
  fontReg = new Font;
  fontBold = new Font;
  fontIt = new Font;
  fontKanji = new Font;

  load(fontReg,fontRegfile);
  load(fontBold,fontBoldfile);
  load(fontIt,fontItfile);
  load(fontKanji, fontKanjifile);


  // Define the window plus all default options.
  auto window = new RenderWindow(VideoMode(width,height),"Dlang Mahjong");
  window.setFramerateLimit(60);

  // Have some kind of a title screen. Why? I have no idea; everyone does it!
//  titlescreen(window);

  // Enter the main menu.
  mainmenu(window);
}
