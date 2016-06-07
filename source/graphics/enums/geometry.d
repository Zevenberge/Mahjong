module mahjong.graphics.enums.geometry;

import dsfml.system.vector2;

enum iconSpacing = 25;
enum iconSize = 150;
enum width = 900; //Width of application window
enum height = 900; //Height of application window
Vector2f CENTER = Vector2f(width/2, height/2);
enum selectionMargin = 5;
enum openMargin {edge = 15, avatar = 5};

// discard constants
enum discardsPerLine = 6;
enum discardLines = 3;
enum discardUndershoot = 1.3;

//enum stick {width = 399, height = 72};
enum stick {width = 300, height = 20, x0 = 0, y0 = 1};
//enum tile {width = 43, height = 59, x0 = 4, y0 = 1, dx = 45, dy = 61, displayWidth = 35};
enum tile {width = 43, height = 59, x0 = 4, y0 = 1, dx = 45, dy = 61, displayWidth = 30};
enum tileSelectionSize = Vector2f(tile.displayWidth + 2*selectionMargin, tile.displayWidth/tile.height * tile.width + 2*selectionMargin);
enum wallMargin = 2;