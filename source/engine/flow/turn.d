module mahjong.engine.flow.turn;

import mahjong.domain.player;
import mahjong.engine.flow;

class TurnFlow : Flow
{
	this(Player player)
	{
		_player = player;
	}
	
	private Player _player;
	
	override void checkProgress()
	{
		
	}
	
	private void advance()
	{

	}
}