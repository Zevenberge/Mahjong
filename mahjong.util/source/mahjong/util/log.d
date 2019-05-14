module mahjong.util.log;

public import std.experimental.logger : LogLevel;

import std.experimental.logger;
import std.format;

enum logAspect(LogLevel logLevel, string Message) =
q{
    import std.experimental.logger : %1$s;
    %1$s("Begin: %2$s");
    scope(exit) %1$s("End: %2$s");
}.format(logLevel, Message);