module mahjong.graphics.cache.texture;

import dsfml.graphics.texture;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;

Texture tilesTexture;
Texture infoTexture;
Texture splashTexture;
Texture stickTexture;

static this()
{
	infoTexture = new Texture;
	load(infoTexture, infoBgFile);
	stickTexture = new Texture;
	stickTexture.loadFromFile(sticksFile, stick);
}