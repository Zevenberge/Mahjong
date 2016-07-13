module mahjong.graphics.meta;

mixin template delegateCoords(string[] args)
{
	import mahjong.graphics.coords;
	
	private FloatCoords _coords;
	
	FloatCoords getCoords()
	{
		mixin(`return FloatCoords(` ~ args[0] ~ 
			`.position, ` ~ args [0] ~ `.rotation);`);
	}
	
	void setCoords(FloatCoords coords)
	{
		mixin(writeOutInner(args));
		_coords = coords;
	}
	private static string writeOutInner(string[] args)
	{
		auto str = "";
		foreach(item; args)
		{
			str ~=
				item ~ `.position = coords.position;` ~
				item ~ `.rotation = coords.rotation;`;
		}
		return str;
	}
}

