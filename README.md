# D Module Dependency Visualizer

A tool to analyze and visualize dependencies between modules in D projects.

## Features

- Parses D source files and extracts import statements
- Builds a directed graph of module dependencies
- Outputs dependency graph as a GraphViz DOT file
- Automatically generates visual representations (PNG, SVG, etc.)
- Provides text-based visualization for quick inspection
- Provides colored visualization with helpful annotations
- Traverses directories recursively to find all D files

## Example Output

When visualized as an image, the graph looks like this:

![Module Dependency Example](https://via.placeholder.com/800x400?text=Module+Dependency+Graph+Example)

When visualized as text, the output looks like:

```
Module Dependency Graph:
=======================
example.app
  └─ example.config
  └─ example.data.model
  └─ example.utils.helper
  └─ std.file
  └─ std.path
  └─ std.stdio

example.config
  └─ example.utils.helper
  └─ std.file
  └─ std.json
  └─ std.stdio

...
```

## Requirements

- D compiler (DMD, LDC, or GDC)
- DUB package manager
- GraphViz (required for image generation)

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/module_viz.git
cd module_viz

# Build with DUB
dub build
```

## Usage

Basic commands for running the tool:

```bash
# Windows
.\bin\module_viz.exe --input=path\to\project --output=graph.dot --image --text

# Linux/macOS
./bin/module_viz --input=path/to/project --output=graph.dot --image --text
```

Available options:

```
--input=PATH, -i       Directory containing D source files to analyze (default: current directory)
--output=FILE, -o      Output .dot file (default: dependency_graph.dot)
--image, --img         Automatically generate image from the dot file
--format=FORMAT, -f    Image format (png, svg, pdf, etc.) when using --image (default: png)
--text, -t             Display text-based visualization of the dependency graph
--help, -h             Show help information
```

## Running on Windows

```powershell
# Build the project
dub build

# Run the tool with text-based visualization
.\bin\module_viz.exe --input=example --text

# Generate both DOT file and PNG image
.\bin\module_viz.exe --input=example --output=example.dot --image

# Open the generated PNG (if GraphViz is installed)
example.png
```

## Running on Linux/macOS

```bash
# Build the project
dub build

# Run the tool with text-based visualization
./bin/module_viz --input=example --text

# Generate both DOT file and PNG image
./bin/module_viz --input=example --output=example.dot --image

# Open the generated PNG (if GraphViz is installed)
# Linux
xdg-open example.png
# macOS
open example.png
```

## Output

The tool generates a .dot file that can be visualized using GraphViz. With the `--image` flag, it will automatically generate the visualization for you. If GraphViz is not installed, you can use the `--text` option to see a text-based representation.

```bash
# Manual visualization if not using --image flag
dot -Tpng dependency_graph.dot -o dependency_graph.png
dot -Tsvg dependency_graph.dot -o dependency_graph.svg
```

## Node Colors

In the generated graph:

- **Light Green**: Base modules (only imported by others)
- **Salmon**: Entry points (only import others)
- **Gold**: Hub modules (heavily connected)
- **Light Blue**: Regular modules

## Implementation Details

The visualizer works in these steps:

1. Recursively find all D source files in the specified directory
2. For each file:
   - Extract the module name from the module declaration or file path
   - Parse and extract all import statements
3. Build a dependency graph based on the imports
4. Generate a DOT file with appropriate attributes for visualization
5. If requested, output a text-based visualization of the dependency graph
6. If requested, automatically convert the DOT file to an image using GraphViz

## Example Project

The repository includes an example D project in the `example/` directory that demonstrates a typical module structure with dependencies. You can run the visualizer on it to see how the output looks:

```bash
# Generate DOT file, text visualization, and PNG image
./module_viz --input=example --output=example_dependencies.dot --text --image
```

## Troubleshooting

- **GraphViz not found**: Install GraphViz from https://graphviz.org/download/ and ensure the 'dot' command is in your PATH.
- **Online alternatives**: If you can't install GraphViz, you can use online tools like:
  - https://dreampuf.github.io/GraphvizOnline/
  - https://edotor.net/
  - https://sketchviz.com/

## License

Proprietary

## Dependencies

- [libdparse](https://github.com/dlang-community/libdparse) - D language parsing library
