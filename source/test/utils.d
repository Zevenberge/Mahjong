module mahjong.test.utils;

version(unittest)
{
	import std.experimental.logger;

    deprecated("Use fluent.asserts: x.should.be.instanceOf!T")
	bool isOfType(T, S)(S obj)
	{
		auto result = cast(T)obj !is null;
	//	if(!result) error("Expected ", T.stringof, " but was ", typeid(obj));
		return result;
	}
}
