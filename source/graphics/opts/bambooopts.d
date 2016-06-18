module mahjong.graphics.opts.bambooopts;

import mahjong.graphics.opts.defaultopts;
import mahjong.graphics.opts.opts;

class BambooDrawingOpts : DefaultDrawingOpts
{
	override float rotationPerPlayer()
	{
		return 180;
	}
}