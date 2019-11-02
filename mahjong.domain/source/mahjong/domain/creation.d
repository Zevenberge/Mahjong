module mahjong.domain.creation;

import std.experimental.logger;
import std.range;
import std.random;
import std.string;
import mahjong.domain.enums;
import mahjong.domain.tile;
import mahjong.util.allocator;

auto allTiles() pure @nogc nothrow
{
    struct Result
    {
        private int type = Types.wind;
        private int value = Winds.east;

        ComparativeTile front() pure const @nogc nothrow
        {
            return ComparativeTile(cast(Types)type, value);
        }

        void popFront() pure @nogc nothrow
        {
            ++value;
            if(value == amountOfTiles(cast(Types)type))
            {
                value = 0;
                ++type;
            }
        }

        bool empty() pure const @nogc nothrow
        {
            return type == (Types.ball + 1);
        }
    }
    return Result();
}

unittest
{
    import std.algorithm : any;
    import fluent.asserts;
    auto allocator = Allocator(true);
    auto aWind = ComparativeTile(Types.wind, Winds.east);
    allTiles.any!(tile => aWind.hasEqualValue(tile)).should.equal(true);
    auto aDragon = ComparativeTile(Types.dragon, Dragons.green);
    allTiles.any!(tile => aDragon.hasEqualValue(tile)).should.equal(true);
    auto aCharacter = ComparativeTile(Types.character, Numbers.one);
    allTiles.any!(tile => aCharacter.hasEqualValue(tile)).should.equal(true);
    auto aBamboo = ComparativeTile(Types.bamboo, Numbers.five);
    allTiles.any!(tile => aBamboo.hasEqualValue(tile)).should.equal(true);
    auto aBall = ComparativeTile(Types.ball, Numbers.nine);
    allTiles.any!(tile => aBall.hasEqualValue(tile)).should.equal(true);
    auto noWind = ComparativeTile(Types.wind, Winds.north + 1);
    allTiles.any!(tile => noWind.hasEqualValue(tile)).should.equal(false);
    auto noDragon = ComparativeTile(Types.dragon, Dragons.white + 1);
    allTiles.any!(tile => noDragon.hasEqualValue(tile)).should.equal(false);
    auto noNumber = ComparativeTile(Types.character, Numbers.nine + 1);
    allTiles.any!(tile => noNumber.hasEqualValue(tile)).should.equal(false);
}

void setUpWall(ref Tile[] wall, int dups = 4)
{
	for(int i = 0; i < dups; ++i)
	{
        foreach(tile; allTiles)
        {
            wall ~= new Tile(tile.type, tile.value);
        }
	}
	defineDoras(wall);
}

unittest
{
    import std.algorithm : filter, any;
    import std.array;
    import fluent.asserts;
    Tile[] wall;
    setUpWall(wall);
    wall.length.should.equal(136);
    auto doras = wall.filter!(tile => tile.isDora).array;
    doras.length.should.equal(3);
    auto redFiveCharacter = ComparativeTile(Types.character, Numbers.five);
    doras.any!(tile => tile.hasEqualValue(redFiveCharacter)).should.equal(true);
    auto redFiveBamboo = ComparativeTile(Types.bamboo, Numbers.five);
    doras.any!(tile => tile.hasEqualValue(redFiveBamboo)).should.equal(true);
    auto redFiveBall = ComparativeTile(Types.ball, Numbers.five);
    doras.any!(tile => tile.hasEqualValue(redFiveBall)).should.equal(true);
}

private void defineDoras(ref Tile[] wall) pure
in
{
	assert(wall.length == 136, "Wall length was %s".format(wall.length));
}
body
{
	++wall[11].dora;
	++wall[20].dora;
	++wall[29].dora;
}

version(mahjong_test)
{
    Tile[] convertToTiles(const(dchar)[] faces)
    {
        Tile[] tiles;
        foreach(face; stride(faces,1))
        {
            tiles ~= getTile(face);
        }
        return tiles;
    }
    private Tile getTile(dchar face)
    {
    	dchar[] tiles = defineTiles(); // Always load the default tile set such that the correct Numbers are compared!!
    	Types typeOfTile;
    	int value;
    	int tileNumber;
    	foreach(stone; stride(tiles,1))
    	{
    		if(stone == face)
    		{
    			switch (tileNumber) 
    			{
    				case 0: .. case 3:
    					typeOfTile = Types.wind;
    					value = tileNumber;
    					break;
    				case 4: .. case 6:
    					typeOfTile = Types.dragon;
    					value = tileNumber - 4;
    					break;
    				case 7: .. case 15:
    					typeOfTile = Types.character;
    					value = tileNumber - 7;
    					break;
    				case 16: .. case 24:
    					typeOfTile = Types.bamboo;
    					value = tileNumber - 16;
    					break;
    				case 25: .. case 33:
    					typeOfTile = Types.ball;
    					value = tileNumber - 25;
    					break;
    				default:
    					fatal("Could not identify tile by the face. Terminating program.");
    			}
    			break;
    		}
    		++tileNumber;
    	}
    	auto tile = new Tile(typeOfTile, value);
    	return tile;
    }

    private dchar[] defineTiles()
    {
        dchar[] tiles;
        tiles ~= "🀀🀁🀂🀃🀅🀄🀆🀇🀈🀉🀊🀋🀌🀍🀎🀏🀐🀑🀒🀓🀔🀕🀖🀗🀘🀙🀚🀛🀜🀝🀞🀟🀠🀡"d;
        return tiles;
        /* Set of Mahjong tiles in Unicode format
         🀀     🀁  🀂  🀃  🀄  🀅  🀆  🀇  🀈  🀉  🀊  🀋  🀌  🀍  🀎  🀏
         🀐     🀑  🀒  🀓  🀔  🀕  🀖  🀗  🀘  🀙  🀚  🀛  🀜  🀝  🀞  🀟
         🀠     🀡  🀢  🀣  🀤  🀥  🀦  🀧  🀨  🀩  🀪  🀫
         */
    }
}

void shuffleWall(ref Tile[] wall)
in
{
	assert(wall.length > 0);
}
body
{
    wall = randomShuffle(wall);
}