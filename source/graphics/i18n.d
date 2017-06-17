module mahjong.graphics.i18n;

import std.conv;

string translate(T)(T term)
{
	// TODO: dlangui.i18n.uitstring
	return term.to!string;
}
