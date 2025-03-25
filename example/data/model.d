module example.data.model;

import std.stdio;
import std.array;
import std.algorithm;

import example.utils.helper;
import example.data.storage;

class DataModel
{
    private Helper helper;
    private Storage storage;
    
    this()
    {
        helper = new Helper();
        storage = new Storage();
    }
    
    void process()
    {
        writeln("Processing data model...");
        helper.performTask("data-processing");
        
        auto data = storage.load();
        writefln("Loaded %d data items", data.length);
        
        // Process data
        auto result = data.map!(a => a * 2).array();
        
        storage.save(result);
        writeln("Data processing complete");
    }
} 