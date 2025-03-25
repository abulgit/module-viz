module example.config;

import std.stdio;
import std.file;
import std.json;

import example.utils.helper;

class Config
{
    private string configPath;
    private JSONValue configData;
    
    void load(string path)
    {
        configPath = path;
        
        if (exists(path))
        {
            string content = readText(path);
            configData = parseJSON(content);
            writeln("Configuration loaded from: ", path);
        }
        else
        {
            writeln("Configuration file not found: ", path);
            configData = parseJSON("{}");
        }
    }
    
    string getValue(string key, string defaultValue = "")
    {
        if (key in configData)
        {
            return configData[key].str;
        }
        return defaultValue;
    }
} 