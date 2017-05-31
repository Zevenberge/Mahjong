module mahjong.engine.enums.game;

enum Set {chi, pair, pon, kan};
enum PlayerWinds {east, south, west, north, spring, summer, autumn, winter};
enum Status {SetUp, NewGame, Running, AbortiveDraw, ExhaustiveDraw, Mahjong};
enum Action {Claim, Deny, Discard};
enum Phase {Draw, Discard, End};
enum Interaction {None, Draw, Discard}