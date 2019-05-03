import std.experimental.logger;
import etc.linux.memoryerror;
import mahjong.graphics.ui;

extern(C) void linux_XInitThreads(); // Defined in DSFMLC.
void main(string[] args)
{
    linux_XInitThreads();
    static if (is(typeof(registerMemoryErrorHandler)))
        registerMemoryErrorHandler(); 
    
    sharedLog.logLevel = LogLevel.info;

    info("Starting mahjong application.");
    run();
    info("Mahjong exited normally.");
}