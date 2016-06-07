module mahjong.domain.closedhand;

import dsfml.graphics;
import dsfml.system.vector2;
import mahjong.domain.hand;
import mahjong.domain.tile;
import mahjong.domain.wall;
import mahjong.engine.mahjong;
import mahjong.graphics.graphics;
import enumlist;

class ClosedHand : Hand
{
  void place(const int playLoc)
  {
    /*
       Place the closed hand between two avatars.
    */
    sort_hand(tiles);
    int i = 0;
    foreach(stone; tiles)
    { 
      stone.setPosition(calculatePosition(tiles.length, playLoc, i));
      stone.rotateToPlayer(playLoc);
      ++i;
    }
  }

  private Vector2f calculatePosition(const size_t amountOfTiles, const int playLoc, const int i)
  {
    float[2] position = [width/2, height/2];
    float centering = (width - iconSpacing - amountOfTiles * tile.displayWidth)/2.; // Center the hand between two avatars
    float[2] movement;
    movement[0] = centering + i * tile.displayWidth - position[0];
    movement[1] = height/2 - iconSize; // Align the top of the tiles with the top of the own avatar.
    moveToPlayer(position, movement, playLoc);
    return Vector2f(position[0], position[1]);
  }

  public void closeHand()
  {
     foreach(tile; tiles)
     {
        tile.close;
     }
  }
  public void showHand()
  {
     foreach(tile; tiles)
     {
        tile.open;
     }
  }
  
  public void drawTile(ref Wall wall)
  {
    tiles ~= wall.drawTile;
    selectDrawnTile();
  }
  public Tile getLastTile()
  {
    return tiles[$-1];
  }

  public void draw(ref RenderWindow window, const int playLoc)
  {
     place(playLoc);
     selectOpt();
     foreach(tile; tiles)
     {
       tile.draw(window);
     }
  }

  public void selectDrawnTile()
  {
     auto drawnTile = tiles[$-1];
     sort_hand(tiles);
     for(int i = 0; i < tiles.length; ++i)
     {
       if(is_identical(tiles[i], drawnTile))
       {
          changeOpt(i);
          break;
       }
     }
  }

  public void open()
  {
    foreach(tile; tiles)
    {
       tile.open;
    }
  }
  public void close()
  {
    foreach(tile; tiles)
    {
       tile.close;
    }
  }
}
