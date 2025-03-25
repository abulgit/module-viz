module example.utils.helper;

import std.stdio;
import std.datetime;

import example.utils.logger;

class Helper
{
    private bool initialized;
    private Logger logger;
    
    this()
    {
        logger = new Logger();
    }
    
    void initialize()
    {
        if (!initialized)
        {
            writeln("Helper initialized at: ", Clock.currTime());
            logger.log("Helper initialized");
            initialized = true;
        }
    }
    
    void performTask(string taskName)
    {
        if (!initialized)
        {
            initialize();
        }
        
        writeln("Performing task: ", taskName);
        logger.log("Task performed: " ~ taskName);
    }
} 