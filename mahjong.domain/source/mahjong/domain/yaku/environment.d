module mahjong.domain.yaku.environment;

import mahjong.domain.enums;
import mahjong.domain.ingame;
import mahjong.domain.metagame;
import mahjong.domain.tile;

struct Environment
{
    const PlayerWinds leadingWind;
    const PlayerWinds ownWind;
    const bool isRiichi;
    const bool isDoubleRiichi;
    const bool isFirstTurnAfterRiichi;
    const bool isSelfDraw;
    const bool isReplacementTileFromKan;
    const bool isKanSteal;
    const bool isClosedHand;
    const bool isLastTileBeforeExhaustiveDraw;
    const bool isFirstRound;
    const Tile lastTile;
}

package const(Environment) destillEnvironment(const Ingame player, const Metagame metagame) pure @nogc nothrow
{
    Environment env = {
        leadingWind: metagame.leadingWind,
        ownWind: player.wind,
        isRiichi: player.isRiichi,
        isDoubleRiichi: player.isDoubleRiichi,
        isFirstTurnAfterRiichi: player.isFirstTurnAfterRiichi,
        isSelfDraw: player.lastTile.isSelfDraw,
        isReplacementTileFromKan: player.lastTile.isReplacementTileForKan,
        isKanSteal: player.lastTile.isKanSteal,
        isClosedHand: player.isClosedHand,
        isLastTileBeforeExhaustiveDraw: metagame.isExhaustiveDraw && !player.isNagashiMangan,
        isFirstRound: metagame.isFirstTurn,
        lastTile: player.lastTile
    };
    return env;
}

const(Environment) destillEnvironmentForPotentialRon(const Ingame player, const Tile discardedTile,
    PlayerWinds leadingWind, bool isFirstRound, bool isLastTileBeforeExhaustiveDraw) pure @nogc nothrow
{
    Environment env = {
        leadingWind: leadingWind,
        ownWind: player.wind,
        isRiichi: player.isRiichi,
        isDoubleRiichi: player.isDoubleRiichi,
        isFirstTurnAfterRiichi: player.isFirstTurnAfterRiichi,
        isSelfDraw: false,
        isReplacementTileFromKan: false,
        isKanSteal: false,
        isClosedHand: player.isClosedHand,
        isLastTileBeforeExhaustiveDraw: isLastTileBeforeExhaustiveDraw,
        isFirstRound: isFirstRound,
        lastTile: discardedTile
    };
    return env;
}

const(Environment) destillEnvironmentForPotentialKanSteal(const Ingame player, const Tile kanTile,
    PlayerWinds leadingWind, bool isFirstRound, bool isLastTileBeforeExhaustiveDraw) pure @nogc nothrow
{
    Environment env = {
        leadingWind: leadingWind,
        ownWind: player.wind,
        isRiichi: player.isRiichi,
        isDoubleRiichi: player.isDoubleRiichi,
        isFirstTurnAfterRiichi: player.isFirstTurnAfterRiichi,
        isSelfDraw: false,
        isReplacementTileFromKan: false,
        isKanSteal: true,
        isClosedHand: player.isClosedHand,
        isLastTileBeforeExhaustiveDraw: isLastTileBeforeExhaustiveDraw,
        isFirstRound: isFirstRound,
        lastTile: kanTile
    };
    return env;
}