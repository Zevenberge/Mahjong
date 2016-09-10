module mahjong.test.utils;

version(unittest)
{
	bool isOfType(T, S)(S obj)
	{
		return cast(T)obj !is null;
	}
}
