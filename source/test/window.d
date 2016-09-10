module mahjong.test.window;

version(unittest)
{
	import dsfml.graphics;

	class TestWindow : RenderWindow
	{
		Drawable[] drawnObjects;

		override void draw(Drawable drawable, RenderStates states = RenderStates.Default)
		{
			drawnObjects ~= drawable;
		}

		override void display()
		{
			// Do nothing, we are testing!
		}
	}
}

