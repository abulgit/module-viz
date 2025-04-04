# Module Viz - D Dependency Visualizer

A simple tool that helps you understand and visualize how modules in your D projects depend on each other.

![image](https://github.com/user-attachments/assets/2e6ab646-08eb-4ac3-877c-7cbfd56e8512)



This is an example of a dependency graph of that example project generated by Module Viz.

I also tried this in the phobos codebase, the graph looks like this. Yes, this is huge😅 - 


![graph](https://github.com/user-attachments/assets/bcb61ef3-042b-412c-b5c3-07f63fb47af6)


## What does it do?

Module Viz scans your D project, figures out how your modules are connected through imports, and creates visual diagrams that help you understand your codebase structure.

Key features:
- ✅ Creates visual dependency graphs from your D code
- ✅ Shows how modules connect to each other
- ✅ Generates both graphical and text-based visualizations
- ✅ Color-codes modules based on their role in your project
- ✅ Works on Windows, Linux, and macOS

## Getting Started

### Option 1: Download the pre-built executable (recommended)

1. **Download the tool**
   - Go to the [Releases page](https://github.com/abulgit/module-viz/releases)
   - Download the zip file for your platform (e.g., `module-viz-v1.0.0-win-x64.zip` for Windows)

2. **Install it**
   - Extract the zip file to a folder of your choice
   - For convenience, you might want to place `viz.exe` in a dedicated folder like `C:\Tools\ModuleViz` or `~/tools/moduleviz`

3. **Add to your PATH** (optional but recommended)

   On Windows:
   - Right-click on "This PC" or "My Computer" and select "Properties"
   - Click on "Advanced system settings"
   - Click on the "Environment Variables" button
   - Under "System variables" (or "User variables" for just your account), find the "Path" variable and click "Edit"
   - Click "New" and add the folder path where you placed viz.exe (e.g., `C:\Tools\ModuleViz`)
   - Click "OK" on all dialog boxes
   - Restart any open command prompts for the change to take effect

   On Linux/macOS:
   - Edit your `~/.bashrc`, `~/.zshrc`, or equivalent shell configuration file
   - Add this line: `export PATH="$PATH:/path/to/folder/containing/viz"`
   - Save the file and run `source ~/.bashrc` (or appropriate file) or restart your terminal

### Option 2: Build from source

If you prefer to build the tool yourself:

1. **Prerequisites**
   - D compiler (DMD, LDC, or GDC)
   - DUB package manager

2. **Build steps**
   ```bash
   # Clone the repository
   git clone https://github.com/abulgit/module-viz.git
   cd module-viz

   # Build the project
   dub build

   # The executable will be in the bin directory
   ```

## How to Use

### Basic Usage

```bash
# If added to PATH:
viz --input=path/to/project

# If not added to PATH (Windows):
C:\path\to\viz.exe --input=path/to/project

# If not added to PATH (Linux/macOS):
/path/to/viz --input=path/to/project
```

### Common Commands

Create a dependency graph of your project:
```bash
viz --input=path/to/project --output=graph.dot --image
```

See a text-based graph:
```bash
viz --input=path/to/project --text
```

Get help:
```bash
viz --help
```

### All Available Options

```
--input=PATH, -i       Directory containing D source files to analyze (default: current directory)
--output=FILE, -o      Output .dot file (default: dependency_graph.dot)
--image, --img         Automatically generate image from the dot file
--format=FORMAT, -f    Image format (png, svg, pdf, etc.) when using --image (default: png)
--text, -t             Display text-based visualization of the dependency graph
--help, -h             Show help information
```

## Understanding the Visualization

### Color Meaning

The tool color-codes modules to help you understand their role:

- **Light Green**: Base modules that are only imported by other modules but don't import anything
- **Salmon**: Entry point modules that import other modules but aren't imported by anything
- **Gold**: Hub modules that are heavily connected (both importing and being imported)
- **Light Blue**: Regular modules with balanced dependencies

### Image Generation Requirements

To generate images, you need [GraphViz](https://graphviz.org/download/) installed on your system.

If you don't have GraphViz or can't install it, you can:
1. Use the `--text` option to see a text representation
2. Upload the .dot file to an online GraphViz tool:
   - [GraphvizOnline](https://dreampuf.github.io/GraphvizOnline/)
   - [Edotor](https://edotor.net/)
   - [Sketchviz](https://sketchviz.com/)

## Examples

### Analyzing a D Project

```bash
# Generate a PNG visualization of a project
viz --input=path/to/dproject --image

# Generate an SVG instead of PNG
viz --input=path/to/dproject --image --format=svg

# Show both text and graphical visualization
viz --input=path/to/dproject --text --image
```

### Demo Project

The repository includes an example project in the `example/` directory:

```bash
# Analyze the example project
viz --input=example --output=example.dot --image --text
```

## Troubleshooting

### Common Issues

- **"Command not found"**: Make sure viz is in your PATH or use the full path to the executable
- **Image generation fails**: Install GraphViz from https://graphviz.org/download/
- **No modules found**: Check that you're pointing to a directory with .d files

### Need Help?

If you encounter any issues, please [open an issue](https://github.com/abulgit/module-viz/issues) on GitHub.

## License

Proprietary

## Dependencies

- [libdparse](https://github.com/dlang-community/libdparse) - D language parsing library
