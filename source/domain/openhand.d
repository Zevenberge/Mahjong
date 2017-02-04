module mahjong.domain.openhand;

import dsfml.graphics;

import mahjong.domain.enums.game;
import mahjong.domain;
import mahjong.engine.mahjong;
import mahjong.graphics.drawing.tile;
import mahjong.graphics.enums.geometry;
import mahjong.graphics.manipulation;

class OpenHand
{
	Tile[][amountOfSets] tiles;
	RectangleShape[3] selections;

	void initialiseSelections()
	{
		foreach(rectangle; selections)
		{
			rectangle = new RectangleShape;
			rectangle.fillColor = Color.Yellow;
			rectangle.size = tileSelectionSize;
		}
	}

	void resetSelections()
	{
		foreach(rectangle; selections)
		{
			rectangle.position = Vector2f(0,0);
			rectangle.size = Vector2f(0,0);
		}
	}

	void placeKanSelections(Tile[] hand, Tile dibsable)
	{
		placeIdenticals(hand, dibsable, 4);
	}

	void placePonSelections(Tile[] hand, Tile dibsable)
	{
		placeIdenticals(hand, dibsable, 3);
	}

	void placePairSelections(Tile[] hand, Tile dibsable)
	{
		placeIdenticals(hand, dibsable, 2);
	}

	void placeIdenticals(Tile[] hand, Tile dibsable, int amountOfIdenticals)
	{
		resetSelections;
		int i = 0;
		foreach(tile; hand)
		{
			if(tile.hasEqualValue(dibsable))
			{
				selectTile(tile, i); 
				++i;
				if(!(i < amountOfIdenticals-1))
				{
					break;
				}
			}
		}
	}

	void selectTile(Tile tile, const ref int i)
	{
		FloatRect position = tile.getGlobalBounds;
		selections[i].position = Vector2f(position.left - selectionMargin, position.top - selectionMargin);
		selections[i].size = Vector2f(position.width + 2*selectionMargin, position.height + 2*selectionMargin);
	}

	 void drawSelections(ref RenderWindow window)
	{
		foreach(rectangle; selections)
		{
			window.draw(rectangle);
		}
	} 

	FloatRect getGlobalBounds(int i)
	in
	{ // Assert i is in the range.
		assert(i < amountOfSets);
		assert(i >= 0);
	}
	body
	{
		//TODO: refactor this when ponning is implemented.
		return FloatRect();//return calcGlobalBounds(tiles[][i]);
	}
}
