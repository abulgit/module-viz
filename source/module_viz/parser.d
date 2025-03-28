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
        import std.path : baseName, stripExtension, buildNormalizedPath;

        // Normalize path separators to be consistent
        filePath = buildNormalizedPath(filePath);

        string fileName = baseName(filePath).stripExtension();
        string dir = std.path.dirName(filePath);

        // Special handling for package.d files
        if (fileName == "package") {
            string packageDir = baseName(dir);
            dir = std.path.dirName(dir);

            // Handle nested packages
            string packageName = packageDir;

            // Build package name from directory structure
            while (dir != "." && dir != "/" && baseName(dir) != "source" && baseName(dir) != "src") {
                packageName = baseName(dir) ~ "." ~ packageName;
                dir = std.path.dirName(dir);
            }

            return packageName;
        }

        // For regular modules, use directory structure to infer module name
        if (dir != "." && dir != "/" && baseName(dir) != "source" && baseName(dir) != "src") {
            // Build full module name from directory structure
            string modulePath = fileName;
            while (dir != "." && dir != "/" && baseName(dir) != "source" && baseName(dir) != "src") {
                modulePath = baseName(dir) ~ "." ~ modulePath;
                dir = std.path.dirName(dir);
            }
            return modulePath;
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

    // Improved lexer to remove comments from D source code
    string stripComments(string code) {
        bool inLineComment = false;
        bool inBlockComment = false;
        bool inNestedComment = false;
        int nestedCommentDepth = 0;
        bool inString = false;
        bool inWysiwygString = false;
        bool inDelimitedString = false;
        bool inCharLiteral = false;
        char[] result;

        for (size_t i = 0; i < code.length; i++) {
            // Handle string literals first to avoid misdetecting comments in strings
            if (!inLineComment && !inBlockComment && !inNestedComment) {
                // Check for wysiwyg strings (r"...")
                if (!inString && !inWysiwygString && !inDelimitedString && !inCharLiteral &&
                    i + 1 < code.length && code[i] == 'r' && code[i + 1] == '"') {
                    inWysiwygString = true;
                    result ~= code[i];
                    continue;
                }
                // Check for delimited strings (q"(...)") or similar
                else if (!inString && !inWysiwygString && !inDelimitedString && !inCharLiteral &&
                         i + 1 < code.length && code[i] == 'q' && code[i + 1] == '"') {
                    inDelimitedString = true;
                    result ~= code[i];
                    continue;
                }
                // Regular string handling
                else if (!inWysiwygString && !inDelimitedString && !inCharLiteral &&
                         code[i] == '"' && (i == 0 || code[i - 1] != '\\')) {
                    inString = !inString;
                    result ~= code[i];
                    continue;
                }
                // Character literal
                else if (!inString && !inWysiwygString && !inDelimitedString &&
                         code[i] == '\'' && (i == 0 || code[i - 1] != '\\')) {
                    inCharLiteral = !inCharLiteral;
                    result ~= code[i];
                    continue;
                }
                // End of wysiwyg string
                else if (inWysiwygString && code[i] == '"') {
                    inWysiwygString = false;
                    result ~= code[i];
                    continue;
                }
                // End of delimited string
                else if (inDelimitedString && i + 1 < code.length && code[i] == '"' && code[i + 1] == ')') {
                    inDelimitedString = false;
                    result ~= code[i];
                    continue;
                }
            }

            // Now handle comments
            if (!inString && !inWysiwygString && !inDelimitedString && !inCharLiteral) {
                // Check for start of comments
                if (!inLineComment && !inBlockComment && !inNestedComment && i + 1 < code.length) {
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
                    else if (code[i] == '/' && code[i + 1] == '+') {
                        inNestedComment = true;
                        nestedCommentDepth = 1;
                        i++;
                        continue;
                    }
                }
                // Check for nested comment start while already in a nested comment
                else if (inNestedComment && i + 1 < code.length && code[i] == '/' && code[i + 1] == '+') {
                    nestedCommentDepth++;
                    i++;
                    continue;
                }
                // Check for nested comment end
                else if (inNestedComment && i + 1 < code.length && code[i] == '+' && code[i + 1] == '/') {
                    nestedCommentDepth--;
                    if (nestedCommentDepth == 0) {
                        inNestedComment = false;
                    }
                    i++;
                    continue;
                }
                // Check for end of line comments
                else if (inLineComment && (code[i] == '\n' || code[i] == '\r')) {
                    inLineComment = false;
                    result ~= code[i]; // Keep the newline
                    continue;
                }
                // Check for end of block comments
                else if (inBlockComment && i + 1 < code.length && code[i] == '*' && code[i + 1] == '/') {
                    inBlockComment = false;
                    i++;
                    continue;
                }
            }

            // Add character to result if not in a comment
            if (!inLineComment && !inBlockComment && !inNestedComment) {
                result ~= code[i];
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

        // Validate all dependencies to ensure they have valid module names
        ModuleDependency[] validDependencies;
        foreach (dep; allDependencies) {
            if (isValidModuleName(dep.sourceModule) && isValidModuleName(dep.importedModule)) {
                validDependencies ~= dep;
            } else {
                stderr.writefln("Warning: Skipping invalid module dependency: %s -> %s",
                    dep.sourceModule, dep.importedModule);
            }
        }

        return validDependencies;
    }

    // Validate that a module name follows D language conventions
    private bool isValidModuleName(string moduleName) {
        if (moduleName.length == 0) {
            return false;
        }

        // Simple regex to check if the module name follows D conventions
        // Module names should be composed of identifiers separated by dots
        auto moduleRegex = regex(r"^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$");
        auto match = matchFirst(moduleName, moduleRegex);

        return !match.empty;
    }
}
