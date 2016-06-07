import std.stdio;
import std.random;

import objects;
import mahjong;
import tile_mod;

class aiRandom
{
  Tile Discard(ref Tile[] hand)
  {
    ulong discard = uniform(0,hand.length);
    return hand[discard];
  }

  bool wantToPon(ref Tile[] hand, const ref Tile discard)
  {
    return false;
  }

  bool wantToRon(ref Tile[] hand, const ref Tile discard)
  {
    return true;
  }
}

class aiKyari
{
  Tile Discard(ref Tile[] hand)
  {
    ulong discard;
    size_t handSize = hand.length;
    ulong[] checkedTiles;
    foreach(tile; hand)
    {

    }
    return hand[discard];
  }

  bool wantToPon(ref Tile[] hand, const ref Tile discard)
  {
    return true;
  }

  bool wantToRon(ref Tile[] hand, const ref Tile discard)
  {
    return true;
  }
}
