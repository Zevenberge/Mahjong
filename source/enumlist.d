module enumlist;

import dsfml.graphics;

// Ingame constants.
enum types {season=-1, wind, dragon, character, bamboo, ball};
enum seasons {spring, summer, autumn, fall};
enum winds {east, south, west, north};
enum dragons {green, red, white};
enum characters {one, two, three, four, five, six, seven, eigth, nine};
enum bamboos {one, two, three, four, five, six, seven, eigth, nine};
enum balls {one, two, three, four, five, six, seven, eigth, nine};
enum set {chi, pair, pon, kan};
enum yakus {iihan = 1, ryanan = 2, sanhan = 3, uhan = 5, yakuman = 13, double_yakuman = 26};
enum limit_hands {mangan = 5, haneman = 6, baiman = 8, sanbaiman = 11, yakuman = 13, double_yakuman = 26, triple_yakuman = 39, quadra_yakuman = 52, penta_yakuman = 65, hexa_yakuman = 78, septa_yakuman = 91};
enum playerWinds {east, south, west, north, spring, summer, autumn, winter};
enum origin {wall=-1, east = playerWinds.east, south, west, north};
enum hands {riichi, double_riichi, ippatsu, tsumo, tanyao, pinfu, iipeikou, sanshoukudoujun, itsu, fanpai, chanta, rinshan, chankan, haitei, 
            chiitoitsu, sanankou, sankantsu, toitoi, honitsu, shousangen, honroutou, junchan, ryanpeikou, chinitsu, nagashimangan,
            kokushimusou, chuurenpooto, tenho, chiho, renko, suuankou, suukantsu, ryuuiisou, chinrouto, tsuuiisou, daisangen, shousuushii, daisuushii};

enum kanji {東,南,西,北,春,夏,秋,冬};

// Geometric constants.
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

// File constants. 
enum defaultTexture = "res/404.png";
enum riichiFile = "res/riichi_mahjong.png";
enum chineseFile = "res/chinese_mahjong.png";
enum bambooFile = "res/bamboo.png";
enum eightPlayerFile = "res/eightplayer.png";
enum quitFile = "res/quit.png";
enum tableFile = "res/wood.png";
enum sticksFile = "res/riichisticks.png";
enum tilesFile = "res/tilesscan.png";
string fontRegfile = "fonts/LiberationSans-Regular.ttf";
string fontBoldfile = "fonts/LiberationSans-Bold.ttf";
string fontItfile = "fonts/LiberationSans-Italic.ttf";
string fontKanjifile = "fonts/WrittenKanji.ttf";
alias menuFontfile = fontItfile;
alias titleFontfile = fontBoldfile;

// Misc.
enum GameMode {Riichi = 0, Bamboo, EightPlayer};
enum playerLocation {bottom, right, top, left};
enum Status {running, newGame, abortiveDraw, exhaustiveDraw, mahjong};
enum Action {Claim, Deny, Discard};
enum amountOfPlayers {normal = 4, bamboo = 2, royale = 8};
enum amountOfSets = 4;
enum criticalPoints = 10_000;

// Wall constants.
enum tilesAtOnce = 4; // Amount of tiles that are distributed in one go.
enum deadWallLength = 14;
enum bambooDeadWall = 0;
enum kanBuffer = 4;


// Global variables
Font fontReg;
Font fontBold;
Font fontIt;
Font fontKanji;
alias menuFont = fontIt;
alias titleFont = fontBold;
alias pointsFont = fontReg;
alias kanjiFont = fontKanji;

