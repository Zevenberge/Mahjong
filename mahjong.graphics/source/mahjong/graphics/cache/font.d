module mahjong.graphics.cache.font;

import dsfml.graphics.font;
import mahjong.graphics.enums.resources;
import mahjong.graphics.manipulation;

Font fontReg;
Font fontBold;
Font fontIt;
Font fontKanji;
Font fontInfo;
alias menuFont = fontIt;
alias titleFont = fontBold;
alias pointsFont = fontReg;
alias kanjiFont = fontKanji;
alias infoFont = fontInfo;

shared static this()
{
	// Load different fonts so that we do not need to load them every screen.. 
	fontReg = new Font;
	fontBold = new Font;
	fontIt = new Font;
	fontKanji = new Font;
	fontInfo = new Font;

	load(fontReg,fontRegfile);
	load(fontBold,fontBoldfile);
	load(fontIt,fontItfile);
	load(fontKanji, fontKanjifile);
	load(fontInfo, fontTypedKanji);

}