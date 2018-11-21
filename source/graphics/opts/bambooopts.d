module mahjong.graphics.opts.bambooopts;

import dsfml.graphics.sprite;
import dsfml.system.vector2;
import mahjong.domain.wall;
import mahjong.graphics.drawing.wall;
import mahjong.graphics.opts;

class BambooDrawingOpts : DefaultDrawingOpts
{
	override float rotationPerPlayer()
	{
		return 180;
	}
	
	override void initialiseWall(const Wall wall)
	in
	{
		assert((cast(BambooWall)wall) !is null);
	}
	do
	{
		auto bWall = cast(BambooWall)wall;
		initialiseTiles(bWall);
	}

	override void placeCounter(Sprite counter) 
	{
		super.placeCounter(counter);
		counter.move(Vector2f(0, -50));
	}

    override void placeRiichiStick(Sprite stick) 
    {
        super.placeCounter(stick);
        stick.move(Vector2f(0, 50-stick.getGlobalBounds().height));
    }
}