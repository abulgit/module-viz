module example.app;

import std.stdio;
import std.file;
import std.path;

import example.config;
import example.utils.helper;
import example.data.model;

void main()
{
    writeln("Sample D application for testing module dependencies");
    
    auto config = new Config();
    config.load("config.json");
    
    auto helper = new Helper();
    helper.initialize();
    
    auto model = new DataModel();
    model.process();
    
    writeln("Application finished.");
} 