module mahjong.engine.enums.game;

enum Set {chi, pair, pon, kan};
enum PlayerWinds {east, south, west, north, spring, summer, autumn, winter};
enum Origin {wall=-1, east = PlayerWinds.east, south, west, north};
enum Status {Running, NewGame, AbortiveDraw, ExhaustiveDraw, Mahjong, SetUp};
enum Action {Claim, Deny, Discard};
enum Phase {Draw, Discard, End};