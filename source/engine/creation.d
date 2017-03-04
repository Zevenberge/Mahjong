module mahjong.engine.creation;

import std.experimental.logger;
import std.range;
import std.random;
import std.string;
import mahjong.domain.enums.tile;
import mahjong.domain.tile;
import mahjong.engine.sort;

void setUpWall(ref Tile[] wall, int dups = 4)
{
	for(int i = 0; i < dups; ++i)
	{
		wall ~= createSetOfTiles();
	}
	defineDoras(wall);
}

Tile[] createSetOfTiles() 
{
	dchar[] tiles = defineTiles(); // First load all mahjong tiles.
	return convertToTiles(tiles);
}

Tile[] convertToTiles(const(dchar)[] faces)
{
	Tile[] tiles;
	foreach(face; stride(faces,1))
	{
		tiles ~= getTile(face);
	}
	return tiles;
}

private void defineDoras(ref Tile[] wall)
in
{
	assert(wall.length == 136, "Wall length was %s".format(wall.length));
}
body
{
	++wall[44].dora;
	++wall[80].dora;
	++wall[116].dora;
}


private dchar[] defineTiles()
{
	dchar[] tiles;
	tiles ~= "🀀🀁🀂🀃🀅🀄🀆🀇🀈🀉🀊🀋🀌🀍🀎🀏🀐🀑🀒🀓🀔🀕🀖🀗🀘🀙🀚🀛🀜🀝🀞🀟🀠🀡"d;
	return tiles;
	/* Set of Mahjong tiles in Unicode format
	 🀀 	🀁 	🀂 	🀃 	🀄 	🀅 	🀆 	🀇 	🀈 	🀉 	🀊 	🀋 	🀌 	🀍 	🀎 	🀏
	 🀐 	🀑 	🀒 	🀓 	🀔 	🀕 	🀖 	🀗 	🀘 	🀙 	🀚 	🀛 	🀜 	🀝 	🀞 	🀟
	 🀠 	🀡 	🀢 	🀣 	🀤 	🀥 	🀦 	🀧 	🀨 	🀩 	🀪 	🀫
	 */
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
	tile.face = face;
	return tile;
}
unittest{
	import std.stdio;
	writeln("Checking the labelling of the wall...");
	Tile[] wall;
	setUpWall(wall);
	foreach(stone; wall)
	{
		if (stone.face == '🀀')
		{
			assert(stone.type == Types.wind);
			assert(stone.value == Winds.east);
		} 
		else if (stone.face == '🀏')
		{  
			assert(stone.type == Types.character);
			assert(stone.value == Numbers.nine);
		}
	}
	writeln(" The tiles are correctly labelled.");
}

void shuffleWall(ref Tile[] wall)
in
{
	assert(wall.length > 0);
}
body
{
	for(int i=0; i<500; ++i)
	{
		ulong t1 = uniform(0, wall.length);
		ulong t2 = uniform(0, wall.length);
		swapTiles(wall[t1],wall[t2]);
	}
}