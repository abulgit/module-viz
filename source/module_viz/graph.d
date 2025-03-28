module module_viz.graph;

import std.stdio;
import std.file;
import std.string;
import std.array;
import std.algorithm;
import std.conv;

import module_viz.parser;

/*
 * Represents a dependency graph of D modules.
 * Handles building, visualizing, and exporting the dependency relationships.
 */
class DependencyGraph {
private:
    // Maps module names to their direct dependencies (imports)
    string[][string] adjacencyList;

    // List of all module names in the graph
    string[] moduleNames;

public:
    this(ModuleDependency[] dependencies) {
        buildGraph(dependencies);
    }

    private void buildGraph(ModuleDependency[] dependencies) {
        adjacencyList.clear();
        moduleNames = [];
        bool[string] uniqueModules;

        foreach (dep; dependencies) {
            // Add source module to adjacency list if not already present
            if (dep.sourceModule !in adjacencyList) {
                adjacencyList[dep.sourceModule] = [];
            }

            // Add the dependency if it doesn't already exist
            if (!adjacencyList[dep.sourceModule].canFind(dep.importedModule)) {
                adjacencyList[dep.sourceModule] ~= dep.importedModule;
            }

            // Track all unique modules for later processing
            uniqueModules[dep.sourceModule] = true;
            uniqueModules[dep.importedModule] = true;
        }

        moduleNames = uniqueModules.keys;
        sort(moduleNames);
    }

    // Export the dependency graph to DOT format for visualization
    void saveToDot(string filename) {
        auto file = File(filename, "w");

        file.writeln("digraph ModuleDependencies {");
        file.writeln("  rankdir=LR;");  // Left-to-right layout
        file.writeln("  node [shape=box, fontname=\"Arial\", fontsize=10];");
        file.writeln("  edge [fontname=\"Arial\", fontsize=9];");

        foreach (moduleName; moduleNames) {
            string escapedName = moduleName.replace("\"", "\\\"");

            // Calculate in/out degree metrics for coloring
            int importCount = 0;
            int importedByCount = 0;

            if (moduleName in adjacencyList) {
                importCount = cast(int)adjacencyList[moduleName].length;
            }

            foreach (source, targets; adjacencyList) {
                if (targets.canFind(moduleName)) {
                    importedByCount++;
                }
            }

            // Color code based on module's role in the dependency graph
            string nodeColor = "lightblue";
            if (importCount == 0 && importedByCount > 0) {
                nodeColor = "lightgreen";  // Base module (imported but imports nothing)
            } else if (importCount > 0 && importedByCount == 0) {
                nodeColor = "salmon";      // Entry point (imports but not imported)
            } else if (importCount > 3 && importedByCount > 3) {
                nodeColor = "gold";        // Hub module (heavily connected)
            }

            file.writefln("  \"%s\" [label=\"%s\\nimports: %d\\nimported by: %d\", style=filled, fillcolor=%s];",
                        escapedName, escapedName, importCount, importedByCount, nodeColor);
        }

        // Write the dependency edges
        foreach (source, targets; adjacencyList) {
            string escapedSource = source.replace("\"", "\\\"");

            foreach (target; targets) {
                string escapedTarget = target.replace("\"", "\\\"");
                file.writefln("  \"%s\" -> \"%s\";", escapedSource, escapedTarget);
            }
        }

        file.writeln("}");
        file.close();
    }

    // Print a text-based tree representation of the dependency graph
    void printTextGraph() {
        writeln("Module Dependency Graph:");
        writeln("=======================");

        // First, print modules that import other modules
        foreach (moduleName; moduleNames.sort!((a, b) => a < b)) {
            if (moduleName in adjacencyList && adjacencyList[moduleName].length > 0) {
                writefln("%s", moduleName);

                foreach (imported; adjacencyList[moduleName].sort!((a, b) => a < b)) {
                    writefln("  └─ %s", imported);
                }

                writeln();
            }
        }

        // Then print modules that are only imported but don't import anything
        bool[string] printedModules;
        foreach (moduleName; moduleNames) {
            if (moduleName in adjacencyList) {
                printedModules[moduleName] = true;
            }
        }

        bool foundOrphans = false;
        foreach (moduleName; moduleNames.sort!((a, b) => a < b)) {
            if (moduleName !in printedModules) {
                if (!foundOrphans) {
                    writeln("Modules with no imports:");
                    writeln("=======================");
                    foundOrphans = true;
                }
                writefln("%s (imported only)", moduleName);
                writeln();
            }
        }
    }
}
