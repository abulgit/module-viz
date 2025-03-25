module example.utils.logger;

import std.stdio;
import std.file;
import std.datetime;
import std.format;

class Logger
{
    private File logFile;
    private bool isOpen;
    
    this()
    {
        try
        {
            logFile = File("application.log", "a");
            isOpen = true;
        }
        catch (Exception e)
        {
            stderr.writeln("Failed to open log file: ", e.msg);
            isOpen = false;
        }
    }
    
    ~this()
    {
        if (isOpen)
        {
            logFile.close();
        }
    }
    
    void log(string message)
    {
        string timestamp = Clock.currTime().toString();
        string logMessage = format("[%s] %s", timestamp, message);
        
        if (isOpen)
        {
            logFile.writeln(logMessage);
            logFile.flush();
        }
        
        debug
        {
            writeln("LOG: ", logMessage);
        }
    }
} 