module mahjong.graphics.opts.bambooopts;

import mahjong.domain.wall;
import mahjong.graphics.drawing.wall;
import mahjong.graphics.opts.defaultopts;
import mahjong.graphics.opts.opts;

class BambooDrawingOpts : DefaultDrawingOpts
{
	override float rotationPerPlayer()
	{
		return 180;
	}
	
	override void initialiseWall(Wall wall)
	in
	{
		assert(cast(BambooWall)wall !is null);
	}
	body
	{
		auto bWall = cast(BambooWall)wall;
		initialiseTiles(bWall);
	}
}