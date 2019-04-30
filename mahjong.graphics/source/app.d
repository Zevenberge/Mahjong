import std.experimental.logger;
import etc.linux.memoryerror;
import mahjong.graphics.ui;

void main(string[] args)
{
    static if (is(typeof(registerMemoryErrorHandler)))
        registerMemoryErrorHandler(); 
    
    sharedLog.logLevel = LogLevel.info;

    info("Starting mahjong application.");
    
    run;
    info("Mahjong exited normally.");
}