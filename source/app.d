module module_viz.main;

import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.string;
import std.array;
import std.process;
import std.conv;
import std.algorithm : canFind;

import module_viz.parser;
import module_viz.graph;

void main(string[] args)
{
	// Default configuration values
	string inputDir = ".";
	string outputFile = "dependency_graph.dot";
	bool generateImage = false;
	string imageFormat = "png";
	bool textOutput = false;
	bool help = false;

	auto helpInfo = getopt(
		args,
		"input|i", "Directory containing D source files to analyze (default: current directory)", &inputDir,
		"output|o", "Output .dot file (default: dependency_graph.dot)", &outputFile,
		"image|img", "Automatically generate image from the dot file", &generateImage,
		"format|f", "Image format (png, svg, pdf, etc.) when using --image (default: png)", &imageFormat,
		"text|t", "Display text-based visualization of the dependency graph", &textOutput,
		"help|h", "Show this help", &help
	);

	if (help || helpInfo.helpWanted)
	{
		defaultGetoptPrinter("D Module Dependency Visualizer\n", helpInfo.options);
		return;
	}

	writeln("Analyzing D files in: ", inputDir);

	// Recursively gather all D source files
	string[] dFiles;
	foreach (string file; dirEntries(inputDir, "*.{d}", SpanMode.depth))
	{
		dFiles ~= file;
	}

	writefln("Found %d D source files", dFiles.length);

	// Parse the files and build dependency graph
	auto parser = new DependencyParser();
	auto dependencies = parser.parseFiles(dFiles);

	auto graph = new DependencyGraph(dependencies);

	graph.saveToDot(outputFile);

	writeln("Dependency graph generated: ", outputFile);

	if (textOutput)
	{
		writeln("\n----- Text-Based Dependency Graph -----\n");
		graph.printTextGraph();
	}

	if (generateImage)
	{
		tryGenerateImage(outputFile, imageFormat);
	}
}

/* Attempts to generate an image visualization using GraphViz
 * Will provide helpful error messages if GraphViz isn't installed
 */
void tryGenerateImage(string dotFile, string format)
{
	try
	{
		// Create the output filename by replacing/adding the appropriate extension
		string imageFile;
		if (dotFile.toLower.endsWith(".dot"))
		{
			imageFile = dotFile[0..$ - 4] ~ "." ~ format;
		}
		else
		{
			imageFile = dotFile ~ "." ~ format;
		}

		// Check if GraphViz is available
		auto dotVersionCmd = executeShell("dot -V 2>&1");

		if (dotVersionCmd.status != 0)
		{
			// GraphViz not found - show helpful instructions
			stderr.writeln("\nImage generation failed: GraphViz not found.");
			stderr.writeln("\n----- How to generate the image manually -----");
			stderr.writeln("1. Install GraphViz from https://graphviz.org/download/");
			stderr.writeln("2. Run the following command to generate the image:");
			stderr.writefln("   dot -T%s \"%s\" -o \"%s\"", format, dotFile, imageFile);
			stderr.writeln("\n----- Alternative online tools -----");
			stderr.writeln("You can also use these online tools to visualize the DOT file:");
			stderr.writeln("- https://dreampuf.github.io/GraphvizOnline/");
			stderr.writeln("- https://edotor.net/");
			stderr.writeln("- https://sketchviz.com/");
			stderr.writeln("\n----- Text-based visualization -----");
			stderr.writeln("You can also use the --text option to see a text-based visualization:");
			stderr.writefln("   .\\bin\\viz.exe --input=%s --text",
				(dirName(dotFile) == ".") ? "." : dirName(dotFile));
			return;
		}

		// Validate the image format is supported by GraphViz
		string[] supportedFormats = ["png", "svg", "pdf", "jpg", "jpeg", "bmp", "gif", "tiff", "ps"];
		if (!supportedFormats.canFind(format.toLower)) {
			stderr.writefln("\nWarning: The format '%s' might not be supported by GraphViz.", format);
			stderr.writeln("Common supported formats are: png, svg, pdf, jpg, jpeg, bmp, gif");
			stderr.writeln("Attempting to generate the image anyway...");
		}

		// Generate the image using the dot command
		writefln("Generating %s image...", format.toUpper);
		auto dotCmd = execute(["dot", "-T" ~ format, dotFile, "-o", imageFile]);

		if (dotCmd.status == 0)
		{
			writefln("Image generated: %s", imageFile);

			// Platform-specific instructions to open the image
			version(Windows) {
				writefln("You can open the image by typing: %s", imageFile);
			} else version(linux) {
				writefln("You can open the image by typing: xdg-open %s", imageFile);
			} else version(OSX) {
				writefln("You can open the image by typing: open %s", imageFile);
			}
		}
		else
		{
			stderr.writefln("Error generating image: %s", dotCmd.output);

			if (dotCmd.output.toLower.canFind("format")) {
				stderr.writefln("\nIt seems the format '%s' is not supported by your GraphViz installation.", format);
				stderr.writeln("Try one of these common formats instead: png, svg, pdf, jpg");
				stderr.writefln("Example: .\\bin\\viz.exe --input=%s --image --format=png",
					(dirName(dotFile) == ".") ? "." : dirName(dotFile));
			}
		}
	}
	catch (Exception e)
	{
		stderr.writeln("\nImage generation failed: ", e.msg);
		stderr.writeln("\nMake sure GraphViz is installed and the 'dot' command is available in your PATH.");
		stderr.writeln("You can download GraphViz from: https://graphviz.org/download/");
	}
}
