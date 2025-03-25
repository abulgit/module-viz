module example.data.storage;

import std.stdio;
import std.file;
import std.path;
import std.json;
import std.array;
import std.conv;

import example.utils.logger;

class Storage
{
    private string dataPath = "data.json";
    private Logger logger;
    
    this()
    {
        logger = new Logger();
    }
    
    int[] load()
    {
        logger.log("Loading data from: " ~ dataPath);
        
        if (!exists(dataPath))
        {
            logger.log("Data file not found, creating sample data");
            return [1, 2, 3, 4, 5];
        }
        
        try
        {
            string content = readText(dataPath);
            auto json = parseJSON(content);
            
            int[] result;
            foreach (item; json.array)
            {
                result ~= to!int(item.integer);
            }
            
            logger.log("Data loaded successfully");
            return result;
        }
        catch (Exception e)
        {
            logger.log("Error loading data: " ~ e.msg);
            return [];
        }
    }
    
    void save(int[] data)
    {
        logger.log("Saving data to: " ~ dataPath);
        
        try
        {
            JSONValue json = JSONValue(data);
            std.file.write(dataPath, json.toString());
            logger.log("Data saved successfully");
        }
        catch (Exception e)
        {
            logger.log("Error saving data: " ~ e.msg);
        }
    }
} 