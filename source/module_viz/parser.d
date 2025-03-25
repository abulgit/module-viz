module module_viz.parser;

import std.stdio;
import std.file;
import std.string;
import std.array;
import std.algorithm;
import std.path;
import std.regex;

// Data structure representing a dependency between two modules
struct ModuleDependency {
    string sourceModule;     // Module that contains the import statement
    string importedModule;   // Module being imported
}

/*
 * Parses D source files to extract module dependencies.
 * Handles various import syntax forms and module declarations.
 */
class DependencyParser {
private:
    // Determine module name from file path when no explicit module declaration exists
    string getModuleName(string filePath) {
        import std.path : baseName, stripExtension;

        string fileName = baseName(filePath).stripExtension();
        string dir = std.path.dirName(filePath);

        // Special handling for package.d files
        if (fileName == "package") {
            string packageDir = baseName(dir);
            dir = std.path.dirName(dir);

            if (dir != ".") {
                return join([baseName(dir), packageDir], ".");
            }
            return packageDir;
        }

        // For regular modules, use directory structure to infer module name
        if (dir != "." && baseName(dir) != "source") {
            return join([baseName(dir), fileName], ".");
        }

        return fileName;
    }

    // Extract the module name from an explicit module declaration
    string extractModuleNameFromDeclaration(string code) {
        auto moduleRegex = regex(r"module\s+([a-zA-Z0-9_.]+)\s*;");
        auto match = matchFirst(code, moduleRegex);

        if (!match.empty) {
            return match[1];
        }

        return null;
    }

    // Extract all import statements from D code
    string[] extractImports(string code) {
        string[] imports;

        // First remove all comments to avoid false matches
        code = stripComments(code);

        auto importRegex = regex(r"import\s+([a-zA-Z0-9_. ,:\n\t]+?)\s*;");
        auto matches = matchAll(code, importRegex);

        foreach (match; matches) {
            string importStatement = match[1].strip();

            // Normalize multi-line imports
            importStatement = importStatement.replace("\n", " ")
                                            .replace("\t", " ");

            // Handle comma-separated imports
            auto importParts = importStatement.split(",");

            foreach (part; importParts) {
                part = part.strip();

                // Handle selective imports: "import std.stdio : writeln"
                if (part.canFind(":")) {
                    part = part.split(":")[0].strip();
                }

                // Handle renamed imports: "import io = std.stdio"
                if (part.canFind("=")) {
                    part = part.split("=")[1].strip();
                }

                if (!part.empty) {
                    imports ~= part;
                }
            }
        }

        return imports;
    }

    // Simple lexer to remove comments from D source code
    string stripComments(string code) {
        bool inLineComment = false;
        bool inBlockComment = false;
        bool inString = false;
        bool inCharLiteral = false;
        char[] result;

        for (size_t i = 0; i < code.length; i++) {
            if (!inString && !inCharLiteral) {
                // Check for start of comments
                if (!inLineComment && !inBlockComment && i + 1 < code.length) {
                    if (code[i] == '/' && code[i + 1] == '/') {
                        inLineComment = true;
                        i++;
                        continue;
                    }
                    else if (code[i] == '/' && code[i + 1] == '*') {
                        inBlockComment = true;
                        i++;
                        continue;
                    }
                }
                // Check for end of comments
                else if (inLineComment && (code[i] == '\n' || code[i] == '\r')) {
                    inLineComment = false;
                }
                else if (inBlockComment && i + 1 < code.length && code[i] == '*' && code[i + 1] == '/') {
                    inBlockComment = false;
                    i++;
                    continue;
                }
            }

            // Track string and character literals to prevent false comment detection
            if (!inLineComment && !inBlockComment) {
                if (code[i] == '\"' && (i == 0 || code[i - 1] != '\\')) {
                    inString = !inString;
                }
                else if (code[i] == '\'' && (i == 0 || code[i - 1] != '\\')) {
                    inCharLiteral = !inCharLiteral;
                }

                if (!inLineComment && !inBlockComment) {
                    result ~= code[i];
                }
            }
        }

        return result.idup;
    }

public:
    // Parse a single D source file and extract its dependencies
    ModuleDependency[] parseFile(string filePath) {
        if (!exists(filePath)) {
            stderr.writefln("File does not exist: %s", filePath);
            return [];
        }

        string content = readText(filePath);
        ModuleDependency[] dependencies;

        // Try to get module name from declaration, fall back to file path
        string moduleName = extractModuleNameFromDeclaration(content);
        if (moduleName is null) {
            moduleName = getModuleName(filePath);
        }

        // Extract all imports from the file
        string[] imports = extractImports(content);

        // Create dependency entries
        foreach (importedModule; imports) {
            dependencies ~= ModuleDependency(moduleName, importedModule);
        }

        return dependencies;
    }

    // Process multiple files and combine their dependencies
    ModuleDependency[] parseFiles(string[] filePaths) {
        ModuleDependency[] allDependencies;

        foreach (filePath; filePaths) {
            try {
                auto deps = parseFile(filePath);
                allDependencies ~= deps;
            } catch (Exception e) {
                stderr.writefln("Error parsing %s: %s", filePath, e.msg);
            }
        }

        return allDependencies;
    }
}
