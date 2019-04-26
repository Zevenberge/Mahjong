module mahjong.engine;

class Engine
{

}


Player[] createPlayers(GameEventHandler[] eventHandlers, Opts opts)
{
    return eventHandlers.map!(d => new Player(d, opts.initialScore)).array;
}