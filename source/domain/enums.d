module mahjong.domain.enums;

enum PlayerWinds {east, south, west, north, spring, summer, autumn, winter};
enum GameMode {Riichi = 0, Bamboo, EightPlayer};
enum Types {season=-1, wind, dragon, character, bamboo, ball};
enum Seasons {spring, summer, autumn, fall};
enum Winds {east, south, west, north};
enum Dragons {green, red, white};
enum Numbers {one, two, three, four, five, six, seven, eight, nine};

int amountOfTiles(const Types type)
{
	final switch(type) with(Types)
	{
		case season, wind:
			return 4;
		case dragon:
			return 3;
		case character, bamboo, ball:
			return 9;
	}
}