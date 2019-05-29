module mahjong.ai.testing;

version(mahjong_test)
{
    import mahjong.ai.data;
    import mahjong.domain.creation;
    import mahjong.domain.player;
    Hand hand(dstring tiles)
    {
        return Hand(tiles.convertToTiles);
    }

    Player player()
    {
         return new Player(30_000);
    }
}