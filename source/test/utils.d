module mahjong.test.utils;

version(unittest)
{
	import std.experimental.logger;

	bool isOfType(T, S)(S obj)
	{
		auto result = cast(T)obj !is null;
		if(!result) error("Expected ", T.stringof, " but was ", typeid(obj));
		return result;
	}
}
