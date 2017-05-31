module mahjong.engine.enums.game;

enum Set {chi, pair, pon, kan};
enum PlayerWinds {east, south, west, north, spring, summer, autumn, winter};
enum Action {Claim, Deny, Discard};
enum Phase {Draw, Discard, End};
enum Interaction {None, Draw, Discard}